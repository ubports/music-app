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

from autopilot.input import Mouse, Touch, Pointer
from autopilot.platform import model
from autopilot.testcase import AutopilotTestCase

from time import sleep

from ubuntuuitoolkit import emulators as uitk
from music_app.emulators.emulators import MainView

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

    def setUp(self):
        self._patch_home()
        self._create_music_library()
        self.pointing_device = Pointer(self.input_device_class.create())
        super(MusicTestCase, self).setUp()
        if os.path.exists(self.local_location):
            self.launch_test_local()
        elif os.path.exists(self.installed_location):
            self.launch_test_installed()
        else:
            self.launch_test_click()

    def launch_test_local(self):
        self.app = self.launch_test_application(
            "qmlscene",
            self.local_location,
            app_type='qt')

    def launch_test_installed(self):
        self.app = self.launch_test_application(
            "qmlscene",
            self.installed_location,
            "--desktop_file_hint=/usr/share/applications/music-app.desktop",
            app_type='qt')

    def launch_test_click(self):
        self.app = self.launch_click_package(
            "com.ubuntu.music-app",
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    def _patch_home(self):
        #temp_dir = tempfile.mkdtemp()
        temp_dir = "/home/autopilot-music-app"
        os.mkdir(temp_dir)
        self.addCleanup(shutil.rmtree, temp_dir)
        patcher = mock.patch.dict('os.environ', {'HOME': temp_dir})
        patcher.start()
        self.addCleanup(patcher.stop)

    def _create_music_library(self):
        #use fake home
        home = os.environ['HOME']
        musicpath = home + '/Music'
        mediascannerpath = home + '/.cache/mediascanner'
        os.mkdir(musicpath)
        #os.mkdir(home + '/.cache/')
        #os.mkdir(mediascannerpath)

        #need to fake mediascanner in order for tests to work
        #stop the scanner service
        os.system("stop mediascanner")

        #backup it's index
        #shutil.move(, )
        #copy over our index
        print "home is " + str(home)
        os.system("ls -al " + str(home))
        shutil.copytree(self.working_dir + '/music_app/content/mediascanner',
                        mediascannerpath)
        print "cache copied to " + str(mediascannerpath)
        os.system("ls -al " + str(mediascannerpath))
        #restore the original index after

        #restart the service after
        #adding cleanup step seems to restart service immeadiately; disabling for now
        #self.addCleanup(os.system("start mediascanner"))

        if os.path.exists(self.local_location):
            shutil.copy(self.working_dir + '/music_app/content/'
                +'1.ogg',
                musicpath)
            shutil.copy(self.working_dir + '/music_app/content/'
                +'2.ogg',
                musicpath)
        else:
            shutil.copy('/usr/lib/python2.7/dist-packages/music_app/content/'
            +'1.ogg',
            musicpath)
            shutil.copy('/usr/lib/python2.7/dist-packages/music_app/content/'
            +'2.ogg',
            musicpath)

        print "music copied to " + str(musicpath)
        os.system("ls -al " + str(musicpath))

        #sleep(600)

    @property
    def main_view(self):
        return MainView(self.app)
