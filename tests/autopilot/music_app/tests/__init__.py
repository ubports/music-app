# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Music app autopilot tests."""

import tempfile

import mock
import os
import os.path
import shutil
#import subprocess
import logging

from autopilot.input import Mouse, Touch, Pointer
from autopilot.platform import model
from autopilot.testcase import AutopilotTestCase

from ubuntuuitoolkit import emulators as toolkit_emulators
from music_app import emulators

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
        launch, self.test_type = self.setup_environment()
        if self.test_type != 'click':
            self.home_dir = self._patch_home()
        else:
            self.home_dir = self._save_home()
        self._create_music_library()
        self.pointing_device = Pointer(self.input_device_class.create())
        super(MusicTestCase, self).setUp()
        launch()

    def launch_test_local(self):
        logger.debug("Running via local installation")
        self.app = self.launch_test_application(
            "qmlscene",
            self.local_location,
            app_type='qt',
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    def launch_test_installed(self):
        logger.debug("Running via installed debian package")
        self.app = self.launch_test_application(
            "qmlscene",
            self.installed_location,
            "--desktop_file_hint=/usr/share/applications/music-app.desktop",
            app_type='qt',
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    def launch_test_click(self):
        logger.debug("Running via click package")
        self.app = self.launch_click_package(
            "com.ubuntu.music",
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    def _save_home(self):
        logger.debug('Saving HOME')
        home_dir = os.environ['HOME']
        backup_list = ('Music', )  # '.cache/mediascanner')
        backup_path = [os.path.join(home_dir, i) for i in backup_list]
        backups = [(i, '%s.bak' % i) for i in backup_path if os.path.exists(i)]
        for b in backups:
            logger.debug('backing up %s to %s' % b)
            try:
                shutil.rmtree(b[1])
            except:
                pass
            shutil.move(b[0], b[1])
            #self.addCleanup(shutil.move(b[1], b[0]))
        return home_dir

    def _patch_home(self):
        #make a temp dir
        temp_dir = tempfile.mkdtemp()
        #delete it, and recreate it to the length
        #required so our patching the db works
        #require a length of 25
        shutil.rmtree(temp_dir)
        temp_dir = temp_dir.ljust(25, 'X')
        os.mkdir(temp_dir)
        logger.debug("Created fake home directory " + temp_dir)
        self.addCleanup(shutil.rmtree, temp_dir)
        #if the Xauthority file is in home directory
        #make sure we copy it to temp home, otherwise do nothing
        xauth = os.path.expanduser(os.path.join('~', '.Xauthority'))
        if os.path.isfile(xauth):
            logger.debug("Copying .Xauthority to fake home " + temp_dir)
            shutil.copyfile(
                os.path.expanduser(os.path.join('~', '.Xauthority')),
                os.path.join(temp_dir, '.Xauthority'))
        patcher = mock.patch.dict('os.environ', {'HOME': temp_dir})
        patcher.start()
        logger.debug("Patched home to fake home directory " + temp_dir)
        self.addCleanup(patcher.stop)
        return temp_dir

    def _create_music_library(self):
        logger.debug("Creating music library for %s test" % self.test_type)
        logger.debug("Home set to %s" % self.home_dir)
        musicpath = os.path.join(self.home_dir, 'Music')
        logger.debug("Music path set to %s" % musicpath)
        mediascannerpath = os.path.join(self.home_dir, '.cache/mediascanner')
        os.mkdir(musicpath)
        logger.debug("Mediascanner path set to %s" % mediascannerpath)

        #set content path
        if self.test_type == 'local' or self.test_type == 'click':
            content_dir = os.path.join(self.working_dir, 'music_app/content/')
        else:
            content_dir = '/usr/lib/python2.7/dist-packages/music_app/content/'

        logger.debug("Content dir set to %s" % content_dir)

        #stop media scanner
        #if self.test_type == 'click':
        #    subprocess.check_call(['stop', 'mediascanner'])

        #copy content
        shutil.copy(os.path.join(content_dir, '1.ogg'), musicpath)
        shutil.copy(os.path.join(content_dir, '2.ogg'), musicpath)
        shutil.copy(os.path.join(content_dir, '3.mp3'), musicpath)
        if self.test_type != 'click':
            shutil.copytree(os.path.join(content_dir, 'mediascanner'),
                            mediascannerpath)

        logger.debug("Music copied, files " + str(os.listdir(musicpath)))

        if self.test_type != 'click':
            self._patch_mediascanner_home(mediascannerpath)
            logger.debug(
                "Mediascanner database copied, files " +
                str(os.listdir(mediascannerpath)))

        #start media scanner
        #if self.test_type == 'click':
        #    subprocess.check_call(['start', 'mediascanner'])

    def _patch_mediascanner_home(self, mediascannerpath):
        #do some inline db patching
        #patch mediaindex to proper home
        #these values are dependent upon our sampled db
        logger.debug("Patching fake mediascanner database")
        relhome = self.home_dir[1:]
        dblocation = "home/autopilot-music-app"
        dbfoldername = "08efb777-896b-4308-b0bf-1605dfb3c52c"
        #patch mediaindex
        self._file_find_replace(mediascannerpath +
                                "/mediaindex", dblocation, relhome)

        #patch file indexes
        index_template = '%s/%s/_%%s.cfs' % (mediascannerpath, dbfoldername)
        for i in range(5):
            self._file_find_replace(index_template % i, dblocation, relhome)

    def _file_find_replace(self, in_filename, find, replace):
        #replace all occurences of string find with string replace
        #in the given file
        out_filename = in_filename + ".tmp"
        infile = open(in_filename, 'r')
        outfile = open(out_filename, 'w')
        for s in infile.xreadlines():
            outfile.write(s.replace(find, replace))
        infile.close()
        outfile.close()

        #remove original file and copy new file back
        os.remove(in_filename)
        os.rename(out_filename, in_filename)

    @property
    def main_view(self):
        return self.app.select_single(emulators.MainView)
