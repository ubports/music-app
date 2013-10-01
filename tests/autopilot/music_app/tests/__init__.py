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
import logging

from autopilot.input import Mouse, Touch, Pointer
from autopilot.platform import model
from autopilot.testcase import AutopilotTestCase

from time import sleep

from ubuntuuitoolkit import emulators as uitk
from music_app.emulators.emulators import MainView

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
        #make a temp dir
        temp_dir = tempfile.mkdtemp()
        #delete it, and recreate it to the length
        #required so our patching the db works
        #require a length of 25
        shutil.rmtree(temp_dir)
        temp_dir = temp_dir.ljust(25, 'X')
        os.mkdir(temp_dir)
        logger.debug("Created fake home directory " + str(temp_dir))
        self.addCleanup(shutil.rmtree, temp_dir)
        patcher = mock.patch.dict('os.environ', {'HOME': temp_dir})
        patcher.start()
        logger.debug("Patched home to fake home directory " + str(temp_dir))
        self.addCleanup(patcher.stop)

    def _create_music_library(self):
        #use fake home
        home = os.environ['HOME']
        logger.debug("Home set to " + str(home))
        musicpath = home + '/Music'
        logger.debug("Music path set to " + str(musicpath))
        mediascannerpath = home + '/.cache/mediascanner'
        os.mkdir(musicpath)
        logger.debug("Mediascanner path set to " + str(mediascannerpath))

        #copy over our index
        shutil.copytree(self.working_dir + '/music_app/content/mediascanner',
                        mediascannerpath)

        logger.debug("Mediascanner database copied, files " + str(os.listdir(mediascannerpath)))

        #copy over the music
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

        logger.debug("Music copied, files " + str(os.listdir(musicpath)))

        #do some inline db patching
        #patch mediaindex to proper home
        #these values are dependent upon our sampled db
        logger.debug("Patching fake mediascanner database")
        relhome = home[1:]
        dblocation = "home/autopilot-music-app"
        dbfoldername = "ea50858c-4b21-4f87-9005-40aa960a84a3"
        #patch mediaindex
        os.system("sed -i 's!" + dblocation + "!" + str(relhome) + "!g' " + str(mediascannerpath) + "/mediaindex")

        #patch file indexes
        os.system("sed -i 's!" + dblocation + "!" + str(relhome) + "!g' " + str(mediascannerpath) + "/" + dbfoldername + "/_0.cfs")
        os.system("sed -i 's!" + dblocation + "!" + str(relhome) + "!g' " + str(mediascannerpath) + "/" + dbfoldername + "/_1.cfs")
        os.system("sed -i 's!" + dblocation + "!" + str(relhome) + "!g' " + str(mediascannerpath) + "/" + dbfoldername + "/_2.cfs")
        os.system("sed -i 's!" + dblocation + "!" + str(relhome) + "!g' " + str(mediascannerpath) + "/" + dbfoldername + "/_3.cfs")

    @property
    def main_view(self):
        return MainView(self.app)
