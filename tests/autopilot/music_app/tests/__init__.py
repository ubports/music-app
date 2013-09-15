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

    def setUp(self):
        self._patch_home()
        self._create_music_library()
        self.pointing_device = Pointer(self.input_device_class.create())
        super(MusicTestCase, self).setUp()
        if os.path.exists(self.local_location):
            self.launch_test_local()
        else:
            self.launch_test_installed()

    def launch_test_local(self):
        self.app = self.launch_test_application(
            "qmlscene",
            self.local_location,
            app_type='qt')

    def launch_test_installed(self):
        self.app = self.launch_test_application(
            "qmlscene",
            "/usr/share/music-app/music-app.qml",
            "--desktop_file_hint=/usr/share/applications/music-app.desktop",
            app_type='qt')

    def _patch_home(self):
        temp_dir = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, temp_dir)
        patcher = mock.patch.dict('os.environ', {'HOME': temp_dir})
        patcher.start()
        self.addCleanup(patcher.stop)

    def _create_music_library(self):
        home = os.environ['HOME']
        musicpath = home + '/Music'
        os.mkdir(musicpath)

        # this needs the package 'example-content' installed:
        shutil.copy('/usr/share/example-content/'
            +'Ubuntu_Free_Culture_Showcase/Josh Woodward - Swansong.ogg',
            musicpath)

        if os.path.exists(self.local_location):
            shutil.copy(self.working_dir + '/music_app/content/'
                +'Benjamin_Kerensa_-_Foss_Yeaaaah___Radio_Edit_.ogg',
                musicpath)
        else:
            shutil.copy('/usr/lib/python2.7/dist-packages/music_app/content/'
            +'Benjamin_Kerensa_-_Foss_Yeaaaah___Radio_Edit_.ogg',
            musicpath)

    def tap_item(self, item):
        self.pointing_device.move_to_object(item)
        self.pointing_device.press()
        sleep(1)
        self.pointing_device.release()

    @property
    def main_view(self):
        return MainView(self.app)
