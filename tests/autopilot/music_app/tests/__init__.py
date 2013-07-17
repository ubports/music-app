# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Music app autopilot tests."""

import os.path

from autopilot.input import Mouse, Touch, Pointer
from autopilot.platform import model
from autopilot.testcase import AutopilotTestCase

from time import sleep

from music_app.emulators.main_window import MainWindow


class MusicTestCase(AutopilotTestCase):

    """A common test case class that provides several useful methods for
    music-app tests.

    """
    if model() == 'Desktop':
        scenarios = [('with mouse', dict(input_device_class=Mouse))]
    else:
        scenarios = [('with touch', dict(input_device_class=Touch))]

    local_location = "../../music-app.qml"

    def setUp(self):
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

    def tap_item(self, item):
        self.pointing_device.move_to_object(item)
        self.pointing_device.press()
        sleep(1)
        self.pointing_device.release()

    @property
    def main_window(self):
        return MainWindow(self.app)
