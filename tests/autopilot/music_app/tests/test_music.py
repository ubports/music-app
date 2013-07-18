# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Music app autopilot tests."""

from __future__ import absolute_import

import tempfile

import mock
import os
import os.path
import shutil

from autopilot.matchers import Eventually
from testtools.matchers import Equals

from music_app.tests import MusicTestCase


class TestMainWindow(MusicTestCase):

    def setUp(self):
        self._patch_home()
        self._create_music_library()
        super(TestMainWindow, self).setUp()
        self.assertThat(
            self.main_window.get_qml_view().visible, Eventually(Equals(True)))

    def tearDown(self):
        super(TestMainWindow, self).tearDown()

    def _patch_home(self):
        temp_dir = tempfile.mkdtemp()
        #print('patched home: ' + temp_dir)
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
        
    """ tests if the music library is populated from our fake home directory """
    def test_reads_music_from_home(self):
        main = self.app.select_single("MainView", objectName = "music")
        title = lambda: main.currentTracktitle
        artist = lambda: main.currentArtist
        self.assertThat(title, Eventually(Equals("Swansong")))
        self.assertThat(artist, Eventually(Equals("Josh Woodward")))
    
