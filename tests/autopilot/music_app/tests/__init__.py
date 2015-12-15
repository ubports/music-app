# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright (C) 2013, 2014 Canonical Ltd
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

"""Music app autopilot tests."""

import os
import os.path
import shutil
import sqlite3
import logging
import music_app

import fixtures
from music_app import MusicApp

from autopilot import logging as autopilot_logging
from autopilot.testcase import AutopilotTestCase

import ubuntuuitoolkit
from ubuntuuitoolkit import base

logger = logging.getLogger(__name__)


class BaseTestCaseWithPatchedHome(AutopilotTestCase):

    """A common test case class that provides several useful methods for
    music-app tests.

    """

    working_dir = os.getcwd()
    local_location_dir = os.path.dirname(os.path.dirname(working_dir))
    local_location = local_location_dir + "/app/music-app.qml"
    installed_location = "/usr/share/music-app/app/music-app.qml"

    def get_launcher_method_and_type(self):
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
        super(BaseTestCaseWithPatchedHome, self).setUp()
        self.launcher, self.test_type = self.get_launcher_method_and_type()
        self.home_dir = self._patch_home()
        self._create_music_library()

    @autopilot_logging.log_action(logger.info)
    def launch_test_local(self):
        return self.launch_test_application(
            base.get_qmlscene_launch_command(),
            self.local_location,
            "debug",
            app_type='qt',
            emulator_base=ubuntuuitoolkit.UbuntuUIToolkitCustomProxyObjectBase)

    @autopilot_logging.log_action(logger.info)
    def launch_test_installed(self):
        return self.launch_test_application(
            base.get_qmlscene_launch_command(),
            self.installed_location,
            "debug",
            app_type='qt',
            emulator_base=ubuntuuitoolkit.UbuntuUIToolkitCustomProxyObjectBase)

    @autopilot_logging.log_action(logger.info)
    def launch_test_click(self):
        return self.launch_click_package(
            "com.ubuntu.music",
            emulator_base=ubuntuuitoolkit.UbuntuUIToolkitCustomProxyObjectBase)

    def _copy_xauthority_file(self, directory):
        """ Copy .Xauthority file to directory, if it exists in /home
        """
        # If running under xvfb, as jenkins does,
        # xsession will fail to start without xauthority file
        # Thus if the Xauthority file is in the home directory
        # make sure we copy it to our temp home directory

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

        # if running on non-phablet device,
        # run in temp folder to avoid mucking up home
        # bug 1316746
        # bug 1376423
        if self.test_type is 'click':
            # just use home for now on devices
            temp_dir = os.environ.get('HOME')

            # before each test, remove the app's databases
            local_dir = os.path.join(temp_dir, '.local/share/com.ubuntu.music')

            if (os.path.exists(local_dir)):
                shutil.rmtree(local_dir)

            local_dir = os.path.join(temp_dir, '.config/com.ubuntu.music')

            if (os.path.exists(local_dir)):
                shutil.rmtree(local_dir)
        else:
            temp_dir_fixture = fixtures.TempDir()
            self.useFixture(temp_dir_fixture)
            temp_dir = temp_dir_fixture.path

            # before we set fixture, copy xauthority if needed
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

        # set content path
        content_dir = os.path.join(os.path.dirname(music_app.__file__),
                                   'content')

        logger.debug("Content dir set to %s" % content_dir)

        # copy content
        shutil.copy(os.path.join(content_dir, '1.ogg'), musicpath)
        shutil.copy(os.path.join(content_dir, '2.ogg'), musicpath)
        shutil.copy(os.path.join(content_dir, '3.mp3'), musicpath)

        logger.debug("Music copied, files " + str(os.listdir(musicpath)))

        if self.test_type is not 'click':
            self._patch_mediascanner_home(content_dir, mediascannerpath)

    def _patch_mediascanner_home(self, content_dir, mediascannerpath):
        # do some inline db patching
        # patch mediaindex to proper home
        # these values are dependent upon our sampled db
        shutil.copytree(
            os.path.join(content_dir, 'mediascanner-2.0'), mediascannerpath)
        logger.debug("Patching fake mediascanner database in %s" %
                     mediascannerpath)
        logger.debug(
            "Mediascanner database files " +
            str(os.listdir(mediascannerpath)))

        relhome = self.home_dir[1:]
        dblocation = "home/phablet"
        # patch mediaindex
        self._file_find_replace(mediascannerpath +
                                "/mediastore.sql", dblocation, relhome)

        con = sqlite3.connect(mediascannerpath + "/mediastore.db")
        f = open(mediascannerpath + "/mediastore.sql", 'rb')
        sql = f.read().decode("utf-8")
        cur = con.cursor()
        cur.executescript(sql)
        con.close()

        logger.debug(
            "Mediascanner database copied, files " +
            str(os.listdir(mediascannerpath)))

    def _file_find_replace(self, in_filename, find, replace):
        # replace all occurences of string find with string replace
        # in the given file
        out_filename = in_filename + ".tmp"
        infile = open(in_filename, 'rb')
        outfile = open(out_filename, 'wb')
        for line in infile:
            outfile.write(line.replace(str.encode(find), str.encode(replace)))
        infile.close()
        outfile.close()

        # remove original file and copy new file back
        os.remove(in_filename)
        os.rename(out_filename, in_filename)

class EmptyLibraryWithPatchedHome(AutopilotTestCase):
    
    working_dir = os.getcwd()
    local_location_dir = os.path.dirname(os.path.dirname(working_dir))
    local_location = local_location_dir + "/app/music-app.qml"
    installed_location = "/usr/share/music-app/app/music-app.qml"

    def get_launcher_method_and_type(self):
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
        super(EmptyLibraryWithPatchedHome, self).setUp()
        self.launcher, self.test_type = self.get_launcher_method_and_type()
        self.home_dir = self._patch_home()
        self._create_empty_music_library()

    @autopilot_logging.log_action(logger.info)
    def launch_test_local(self):
        return self.launch_test_application(
            base.get_qmlscene_launch_command(),
            self.local_location,
            "debug",
            app_type='qt',
            emulator_base=ubuntuuitoolkit.UbuntuUIToolkitCustomProxyObjectBase)

    @autopilot_logging.log_action(logger.info)
    def launch_test_installed(self):
        return self.launch_test_application(
            base.get_qmlscene_launch_command(),
            self.installed_location,
            "debug",
            app_type='qt',
            emulator_base=ubuntuuitoolkit.UbuntuUIToolkitCustomProxyObjectBase)

    @autopilot_logging.log_action(logger.info)
    def launch_test_click(self):
        return self.launch_click_package(
            "com.ubuntu.music",
            emulator_base=ubuntuuitoolkit.UbuntuUIToolkitCustomProxyObjectBase)

    def _copy_xauthority_file(self, directory):
        """ Copy .Xauthority file to directory, if it exists in /home
        """
        # If running under xvfb, as jenkins does,
        # xsession will fail to start without xauthority file
        # Thus if the Xauthority file is in the home directory
        # make sure we copy it to our temp home directory

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

        # if running on non-phablet device,
        # run in temp folder to avoid mucking up home
        # bug 1316746
        # bug 1376423
        if self.test_type is 'click':
            # just use home for now on devices
            temp_dir = os.environ.get('HOME')

            # before each test, remove the app's databases
            local_dir = os.path.join(temp_dir, '.local/share/com.ubuntu.music')

            if (os.path.exists(local_dir)):
                shutil.rmtree(local_dir)

            local_dir = os.path.join(temp_dir, '.config/com.ubuntu.music')

            if (os.path.exists(local_dir)):
                shutil.rmtree(local_dir)
        else:
            temp_dir_fixture = fixtures.TempDir()
            self.useFixture(temp_dir_fixture)
            temp_dir = temp_dir_fixture.path

            # before we set fixture, copy xauthority if needed
            self._copy_xauthority_file(temp_dir)
            self.useFixture(fixtures.EnvironmentVariable('HOME',
                                                         newvalue=temp_dir))

            logger.debug("Patched home to fake home directory %s" % temp_dir)
        return temp_dir

    def _patch_mediascanner_home(self, content_dir, mediascannerpath):
        # do some inline db patching
        # patch mediaindex to proper home
        # these values are dependent upon our sampled db
        shutil.copytree(
            os.path.join(content_dir, 'mediascanner-2.0'), mediascannerpath)
        logger.debug("Patching fake mediascanner database in %s" %
                     mediascannerpath)
        logger.debug(
            "Mediascanner database files " +
            str(os.listdir(mediascannerpath)))

        relhome = self.home_dir[1:]
        dblocation = "home/phablet"
        # patch mediaindex
        self._file_find_replace(mediascannerpath +
                                "/blank_mediastore.sql", dblocation, relhome)

        con = sqlite3.connect(mediascannerpath + "/blank_mediastore.db")
        f = open(mediascannerpath + "/blank_mediastore.sql", 'rb')
        sql = f.read().decode("utf-8")
        cur = con.cursor()
        cur.executescript(sql)
        con.close()

        logger.debug(
            "Mediascanner database copied, files " +
            str(os.listdir(mediascannerpath)))

    def _create_empty_music_library(self):
        logger.debug("Creating music library for %s test" % self.test_type)
        logger.debug("Home set to %s" % self.home_dir)
        musicpath = os.path.join(self.home_dir, 'Music')
        logger.debug("Music path set to %s" % musicpath)
        mediascannerpath = os.path.join(self.home_dir,
                                        '.cache/mediascanner-2.0')
        if not os.path.exists(musicpath):
            os.makedirs(musicpath)
        logger.debug("Mediascanner path set to %s" % mediascannerpath)

        # set content path
        content_dir = os.path.join(os.path.dirname(music_app.__file__),
                                   'content')

        logger.debug("Content dir set to %s" % content_dir)

        # don't copy content
        #shutil.copy(os.path.join(content_dir, '1.ogg'), musicpath)
        #shutil.copy(os.path.join(content_dir, '2.ogg'), musicpath)
        #shutil.copy(os.path.join(content_dir, '3.mp3'), musicpath)
        #logger.debug("Music copied, files " + str(os.listdir(musicpath)))

        if self.test_type is not 'click':
            self._patch_mediascanner_home(content_dir, mediascannerpath)

    def _file_find_replace(self, in_filename, find, replace):
        # replace all occurences of string find with string replace
        # in the given file
        out_filename = in_filename + ".tmp"
        infile = open(in_filename, 'rb')
        outfile = open(out_filename, 'wb')
        for line in infile:
            outfile.write(line.replace(str.encode(find), str.encode(replace)))
        infile.close()
        outfile.close()

        # remove original file and copy new file back
        os.remove(in_filename)
        os.rename(out_filename, in_filename)


class MusicAppTestCase(BaseTestCaseWithPatchedHome):

    """Base test case that launches the music-app."""

    def setUp(self):
        super(MusicAppTestCase, self).setUp()
        self.app = MusicApp(self.launcher())

class MusicAppTestCaseEmptyLibrary(EmptyLibraryWithPatchedHome):

    """Test case that launches the music-app with no music: an empty library."""
    
    def setUp(self):
        super(MusicAppTestCaseEmptyLibrary, self).setUp()
        self.app = MusicApp(self.launcher())






