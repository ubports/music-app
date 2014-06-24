# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013, 2014 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Music app autopilot tests."""

import os
import subprocess
import os.path
import shutil
import sqlite3
import logging
import music_app

import fixtures
from music_app import emulators

from autopilot import logging as autopilot_logging
from autopilot.input import Mouse, Touch, Pointer
from autopilot.platform import model
from autopilot.testcase import AutopilotTestCase

from ubuntuuitoolkit import (
    base,
    emulators as toolkit_emulators,
    fixture_setup as toolkit_fixtures
)


logger = logging.getLogger(__name__)


class MusicTestCase(AutopilotTestCase):

    """A common test case class that provides several useful methods for
    music-app tests.

    """
    if model() == 'Desktop':
        scenarios = [('with mouse', dict(input_device_class=Mouse))]
    else:
        scenarios = [('with touch', dict(input_device_class=Touch))]

    working_dir = os.getcwd()
    local_location_dir = os.path.dirname(os.path.dirname(working_dir))
    local_location = local_location_dir + "/music-app.qml"
    installed_location = "/usr/share/music-app/music-app.qml"
    backup_root = os.path.join(
        os.path.expanduser('~'), '.local/share/com.ubuntu.music/backups')

    def setup_environment(self):
        if os.path.exists(self.local_location):
            launch = self.launch_test_local
            test_type = 'local'
        elif os.path.exists(self.installed_location):
            launch = self.launch_test_installed
            test_type = 'deb'
        else:
            launch = self.launch_test_click
            test_type = 'click'
        return launch, test_type

    def setUp(self):
        subprocess.call(["stop", "mediascanner-2.0"])

        # Restart mediascanner on exit
        self.addCleanup(subprocess.call, ["start", "mediascanner-2.0"])

        launch, self.test_type = self.setup_environment()

        #Use backup and restore to setup test environment
        #################################################
        #for now, we will use real /home
        logger.debug("Backup root folder %s" % self.backup_root)

        #backup and wipe before testing
        sqlite_dir = os.path.join(
            os.environ.get('HOME'), '.local/share/com.ubuntu.music/Databases')
        self.backup_folder(sqlite_dir)
        self.addCleanup(lambda: self.restore_folder(sqlite_dir))

        #backup Music folder and restore it after testing
        self.backup_folder(os.path.join(os.environ.get('HOME'), 'Music'))
        self.addCleanup(lambda: self.restore_folder(
                        os.path.join(os.environ.get('HOME'), 'Music')))

        #backup mediascanner folder and restore it after testing
        self.backup_folder(os.path.join(os.environ.get('HOME'),
                                        '.cache/mediascanner-2.0'))
        self.addCleanup(lambda: self.restore_folder(os.path.join(
                        os.environ.get('HOME'),
                        '.cache/mediascanner-2.0')))

        self.home_dir = os.environ['HOME']
        self._create_music_library()
        #################################################
        #Use backup and restore to setup test environment

        #Use mocking fakehome
        #####################
        #self.home_dir = self._patch_home()

        #self._create_music_library()

        ##we need to also tell upstart about our fake home
        ##and we need to do this all in one shell,
        ##also passing along our fake env (env=env)
        #logger.debug("Launching mediascanner")
        #env = os.environ.copy()
        #sethome = "initctl set-env HOME=" + self.home_dir
        #retcode = subprocess.check_output(sethome + "; \
                                          #start mediascanner-2.0",
                                          #env=env,
                                          #stderr=subprocess.STDOUT,
                                          #shell=True)
        #logger.debug("mediascanner launched %s" % retcode)
        #time.sleep(10)

        ##we attempt to reset home for future upstart jobs
        #retcode = subprocess.check_output("initctl reset-env",
                                          #env=env, shell=True)
        #retcode = subprocess.check_output("initctl get-env HOME",
                                          #env=env, shell=True)
        #logger.debug("reset initctl home %s" % retcode)
        #####################
        #Use mocking fakehome

        self.pointing_device = Pointer(self.input_device_class.create())
        super(MusicTestCase, self).setUp()
        launch()

    @autopilot_logging.log_action(logger.info)
    def launch_test_local(self):
        self.app = self.launch_test_application(
            base.get_qmlscene_launch_command(),
            self.local_location,
            "debug",
            app_type='qt',
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    @autopilot_logging.log_action(logger.info)
    def launch_test_installed(self):
        self.app = self.launch_test_application(
            base.get_qmlscene_launch_command(),
            self.installed_location,
            "debug",
            app_type='qt',
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    @autopilot_logging.log_action(logger.info)
    def launch_test_click(self):
        self.app = self.launch_click_package(
            "com.ubuntu.music",
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    def _copy_xauthority_file(self, directory):
        """ Copy .Xauthority file to directory, if it exists in /home
        """
        #If running under xvfb, as jenkins does,
        #xsession will fail to start without xauthority file
        #Thus if the Xauthority file is in the home directory
        #make sure we copy it to our temp home directory

        xauth = os.path.expanduser(os.path.join(os.environ.get('HOME'),
                                   '.Xauthority'))
        if os.path.isfile(xauth):
            logger.debug("Copying .Xauthority to %s" % directory)
            shutil.copyfile(
                os.path.expanduser(os.path.join(os.environ.get('HOME'),
                                   '.Xauthority')),
                os.path.join(directory, '.Xauthority'))

    def _patch_home(self):
        """ mock /home for testing purposes to preserve user data
        """
        #click requires apparmor profile, and writing to special dir
        #but the desktop can write to a traditional /tmp directory
        if self.test_type == 'click':
            env_dir = os.path.join(os.environ.get('HOME'), 'autopilot',
                                   'fakeenv')

            if not os.path.exists(env_dir):
                os.makedirs(env_dir)

            temp_dir_fixture = fixtures.TempDir(env_dir)
            self.useFixture(temp_dir_fixture)

            #apparmor doesn't allow the app to create needed directories,
            #so we create them now
            temp_dir = temp_dir_fixture.path
            temp_dir_cache = os.path.join(temp_dir, '.cache')
            temp_dir_cache_font = os.path.join(temp_dir_cache, 'fontconfig')
            temp_dir_cache_media = os.path.join(temp_dir_cache, 'media-art')
            temp_dir_cache_write = os.path.join(temp_dir_cache,
                                                'tncache-write-text.null')
            temp_dir_config = os.path.join(temp_dir, '.config')
            temp_dir_toolkit = os.path.join(temp_dir_config,
                                            'ubuntu-ui-toolkit')
            temp_dir_font = os.path.join(temp_dir_cache, '.fontconfig')
            temp_dir_local = os.path.join(temp_dir, '.local', 'share')
            temp_dir_confined = os.path.join(temp_dir, 'confined')

            if not os.path.exists(temp_dir_cache):
                os.makedirs(temp_dir_cache)
            if not os.path.exists(temp_dir_cache_font):
                os.makedirs(temp_dir_cache_font)
            if not os.path.exists(temp_dir_cache_media):
                os.makedirs(temp_dir_cache_media)
            if not os.path.exists(temp_dir_cache_write):
                os.makedirs(temp_dir_cache_write)
            if not os.path.exists(temp_dir_config):
                os.makedirs(temp_dir_config)
            if not os.path.exists(temp_dir_toolkit):
                os.makedirs(temp_dir_toolkit)
            if not os.path.exists(temp_dir_font):
                os.makedirs(temp_dir_font)
            if not os.path.exists(temp_dir_local):
                os.makedirs(temp_dir_local)
            if not os.path.exists(temp_dir_confined):
                os.makedirs(temp_dir_confined)

            #before we set fixture, copy xauthority if needed
            self._copy_xauthority_file(temp_dir)
            self.useFixture(toolkit_fixtures.InitctlEnvironmentVariable(
                            HOME=temp_dir))
        else:
            temp_dir_fixture = fixtures.TempDir()
            self.useFixture(temp_dir_fixture)
            temp_dir = temp_dir_fixture.path

            #before we set fixture, copy xauthority if needed
            self._copy_xauthority_file(temp_dir)
            self.useFixture(fixtures.EnvironmentVariable('HOME',
                                                         newvalue=temp_dir))

        logger.debug("Patched home to fake home directory %s" % temp_dir)
        return temp_dir

    def _create_music_library(self):
        logger.debug("Creating music library for %s test" % self.test_type)
        logger.debug("Home set to %s" % self.home_dir)
        musicpath = os.path.join(self.home_dir, 'Music')
        logger.debug("Music path set to %s" % musicpath)
        mediascannerpath = os.path.join(self.home_dir,
                                        '.cache/mediascanner-2.0')
        if not os.path.exists(musicpath):
            os.makedirs(musicpath)
        logger.debug("Mediascanner path set to %s" % mediascannerpath)

        #set content path
        content_dir = os.path.join(os.path.dirname(music_app.__file__),
                                   'content')

        logger.debug("Content dir set to %s" % content_dir)

        #copy content
        shutil.copy(os.path.join(content_dir, '1.ogg'), musicpath)
        shutil.copy(os.path.join(content_dir, '2.ogg'), musicpath)
        shutil.copy(os.path.join(content_dir, '3.mp3'), musicpath)
        shutil.copytree(
            os.path.join(content_dir, 'mediascanner-2.0'), mediascannerpath)

        logger.debug("Music copied, files " + str(os.listdir(musicpath)))

        self._patch_mediascanner_home(mediascannerpath)

        logger.debug(
            "Mediascanner database copied, files " +
            str(os.listdir(mediascannerpath)))

    def _patch_mediascanner_home(self, mediascannerpath):
        #do some inline db patching
        #patch mediaindex to proper home
        #these values are dependent upon our sampled db
        logger.debug("Patching fake mediascanner database in %s" %
                     mediascannerpath)
        logger.debug(
            "Mediascanner database files " +
            str(os.listdir(mediascannerpath)))

        relhome = self.home_dir[1:]
        dblocation = "home/phablet"
        #patch mediaindex
        self._file_find_replace(mediascannerpath +
                                "/mediastore.sql", dblocation, relhome)

        con = sqlite3.connect(mediascannerpath + "/mediastore.db")
        f = open(mediascannerpath + "/mediastore.sql", 'r')
        sql = f.read()
        cur = con.cursor()
        cur.executescript(sql)
        con.close()

    def _file_find_replace(self, in_filename, find, replace):
        #replace all occurences of string find with string replace
        #in the given file
        out_filename = in_filename + ".tmp"
        infile = open(in_filename, 'rb')
        outfile = open(out_filename, 'wb')
        for line in infile:
            outfile.write(line.replace(str.encode(find), str.encode(replace)))
        infile.close()
        outfile.close()

        #remove original file and copy new file back
        os.remove(in_filename)
        os.rename(out_filename, in_filename)

    def backup_folder(self, folder):
        backup_dir = os.path.join(self.backup_root, os.path.basename(folder))
        logger.debug('Backup dir set to %s' % backup_dir)
        try:
            shutil.rmtree(backup_dir)
        except:
            pass
        else:
            logger.warning("Prexisting backup found and removed")

        try:
            shutil.move(folder, backup_dir)
        except shutil.Error as e:
            logger.error('Backup error for %s: %s' % (folder, e))
        except IOError as e:
            logger.error('Backup error for %s: %s' % (folder, e.strerror))
        except:
            logger.error("Unknown error backing up %s" % folder)
        else:
            logger.debug('Backed up %s to %s' % (folder, backup_dir))

    def restore_folder(self, folder):
        backup_dir = os.path.join(self.backup_root, os.path.basename(folder))
        logger.debug('Backup dir set to %s' % backup_dir)
        if os.path.exists(backup_dir):
            if os.path.exists(folder):
                try:
                    shutil.rmtree(folder)
                except shutil.Error as e:
                    logger.error('Restore error for %s: %s' % (folder, e))
                except IOError as e:
                    logger.error('Restore error for %s: %s' %
                                 (folder, e.strerror))
                except:
                    logger.error("Failed to remove test data for %s" % folder)
                    return
            try:
                shutil.move(backup_dir, folder)
            except shutil.Error as e:
                logger.error('Restore error for %s: %s' % (folder, e))
            except IOError as e:
                logger.error('Restore error for %s: %s' % (folder, e.strerror))
            except:
                logger.error('Unknown error restoring %s' % folder)
            else:
                logger.debug('Restored %s from %s' % (folder, backup_dir))
        else:
            logger.warn('No backup found to restore for %s' % folder)

    @property
    def player(self):
        return self.main_view.get_player()

    @property
    def main_view(self):
        return self.app.select_single(emulators.MainView)
