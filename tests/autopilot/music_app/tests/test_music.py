# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Music app autopilot tests."""

from __future__ import absolute_import

from autopilot.matchers import Eventually
from testtools.matchers import Equals, NotEquals, LessThan

from music_app.tests import MusicTestCase

import time


class TestMainWindow(MusicTestCase):

    def setUp(self):
        super(TestMainWindow, self).setUp()
        self.assertThat(
            self.main_view.visible, Eventually(Equals(True)))
        #wait for activity indicator to stop spinning
        self.assertThat(
            self.main_view.get_spinner, Eventually(NotEquals(None)))
        spinner = lambda: self.main_view.get_spinner().running
        self.assertThat(spinner, Eventually(Equals(False)))

    def test_reads_music_library(self):
        """ tests if the music library is populated from our
        fake mediascanner database"""

        title = lambda: self.main_view.currentTracktitle
        artist = lambda: self.main_view.currentArtist
        self.assertThat(title,
                        Eventually(Equals("Foss Yeaaaah! (Radio Edit)")))
        self.assertThat(artist, Eventually(Equals("Benjamin Kerensa")))

    def test_play_pause(self):
        """ Test playing and pausing a track (Music Library must exist) """

        self.main_view.show_toolbar()

        playbutton = self.main_view.get_play_button()

        """ Track is not playing"""
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(False)))
        self.pointing_device.click_object(playbutton)

        """ Track is playing"""
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(True)))

        """ Track is not playing"""
        self.pointing_device.click_object(playbutton)
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(False)))

    def test_play_pause_now_playing(self):
        """ Test playing and pausing a track (Music Library must exist) """

        self.main_view.show_toolbar()

        # switch to the now playing page
        label = self.main_view.get_player_control_title()
        self.pointing_device.click_object(label)

        self.assertThat(self.main_view.get_now_playing_play_button,
                        Eventually(NotEquals(None)))
        playbutton = self.main_view.get_now_playing_play_button()

        """ Track is not playing"""
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(False)))
        self.pointing_device.click_object(playbutton)

        """ Track is playing"""
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(True)))

        """ Track is not playing"""
        self.pointing_device.click_object(playbutton)
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(False)))

    def test_next(self):
        """ Test going to next track (Music Library must exist) """

        self.main_view.show_toolbar()

        # switch to the now playing page
        label = self.main_view.get_player_control_title()
        self.pointing_device.click_object(label)

        forwardbutton = self.main_view.get_forward_button()

        title = lambda: self.main_view.currentTracktitle
        artist = lambda: self.main_view.currentArtist
        self.assertThat(title,
                        Eventually(Equals("Foss Yeaaaah! (Radio Edit)")))
        self.assertThat(artist, Eventually(Equals("Benjamin Kerensa")))

        """ Track is not playing"""
        self.assertThat(self.main_view.isPlaying, Equals(False))
        self.pointing_device.click_object(forwardbutton)

        """ Track is playing"""
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(True)))
        self.assertThat(title, Eventually(Equals("Swansong")))
        self.assertThat(artist, Eventually(Equals("Josh Woodward")))

    def test_previous_and_mp3(self):
        """ Test going to previous track, last item must be an MP3
            (Music Library must exist) """

        self.main_view.show_toolbar()

        # switch to the now playing page
        label = self.main_view.get_player_control_title()
        self.pointing_device.click_object(label)

        self.assertThat(self.main_view.get_repeat_button,
                        Eventually(NotEquals(None)))
        repeatbutton = self.main_view.get_repeat_button()

        self.assertThat(self.main_view.get_previous_button,
                        Eventually(NotEquals(None)))
        previousbutton = self.main_view.get_previous_button()

        title = lambda: self.main_view.currentTracktitle
        artist = lambda: self.main_view.currentArtist
        self.assertThat(title,
                        Eventually(Equals("Foss Yeaaaah! (Radio Edit)")))
        self.assertThat(artist, Eventually(Equals("Benjamin Kerensa")))

        """ Track is not playing, repeat is off"""
        self.assertThat(self.main_view.isPlaying, Equals(False))
        self.pointing_device.click_object(repeatbutton)
        self.pointing_device.click_object(previousbutton)

        """ Track is playing"""
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(True)))
        self.assertThat(title, Eventually(Equals("TestMP3Title")))
        self.assertThat(artist, Eventually(Equals("TestMP3Artist")))

    def test_shuffle(self):
        """ Test shuffle (Music Library must exist) """

        self.main_view.show_toolbar()

        # switch to the now playing page
        label = self.main_view.get_player_control_title()
        self.pointing_device.click_object(label)

        self.assertThat(self.main_view.get_now_playing_play_button,
                        Eventually(NotEquals(None)))
        playbutton = self.main_view.get_now_playing_play_button()

        self.assertThat(self.main_view.get_shuffle_button,
                        Eventually(NotEquals(None)))
        shufflebutton = self.main_view.get_shuffle_button()

        self.assertThat(self.main_view.get_forward_button,
                        Eventually(NotEquals(None)))
        forwardbutton = self.main_view.get_forward_button()

        self.assertThat(self.main_view.get_previous_button,
                        Eventually(NotEquals(None)))
        previousbutton = self.main_view.get_previous_button()

        title = lambda: self.main_view.currentTracktitle
        artist = lambda: self.main_view.currentArtist
        self.assertThat(title,
                        Eventually(Equals("Foss Yeaaaah! (Radio Edit)")))
        self.assertThat(artist, Eventually(Equals("Benjamin Kerensa")))

        """ Track is not playing, shuffle is turned on"""
        self.assertThat(self.main_view.isPlaying, Equals(False))
        self.pointing_device.click_object(shufflebutton)
        self.assertThat(self.main_view.random, Eventually(Equals(True)))

        forward = True
        count = 0
        while True:
            self.assertThat(count, LessThan(10))
            if forward:
                self.pointing_device.click_object(forwardbutton)

                """ Track is playing"""
                self.assertThat(self.main_view.isPlaying,
                                Eventually(Equals(True)))
                if (self.main_view.currentTracktitle == "TestMP3Title" and
                    self.main_view.currentArtist == "TestMP3Artist"):
                        break
                else:
                    forward = not forward
                    count += 1
            else:
                self.pointing_device.click_object(previousbutton)

                """ Track is playing"""
                self.assertThat(self.main_view.isPlaying,
                                Eventually(Equals(True)))
                if (self.main_view.currentTracktitle == "Swansong" and
                    self.main_view.currentArtist == "Josh Woodward"):
                        break
                else:
                    forward = not forward
                    count += 1

            self.pointing_device.click_object(playbutton)
            self.assertThat(self.main_view.isPlaying,
                            Eventually(Equals(False)))
