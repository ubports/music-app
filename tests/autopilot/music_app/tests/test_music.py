# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Music app autopilot tests."""

from __future__ import absolute_import

import time
import logging
from autopilot.matchers import Eventually
from testtools.matchers import Equals, Is, Not, LessThan, NotEquals
from testtools.matchers import GreaterThan


from music_app.tests import MusicTestCase

logger = logging.getLogger(__name__)


class TestMainWindow(MusicTestCase):

    def setUp(self):
        super(TestMainWindow, self).setUp()
        self.assertThat(
            self.main_view.visible, Eventually(Equals(True)))
        #wait for activity indicator to stop spinning
        spinner = lambda: self.main_view.get_spinner().running
        self.assertThat(spinner, Eventually(Equals(False)))

    def test_reads_music_library(self):
        """ tests if the music library is populated from our
        fake mediascanner database"""

        # populate queue
        first_genre_item = self.main_view.get_first_genre_item()
        self.pointing_device.click_object(first_genre_item)

        title = lambda: self.main_view.currentTracktitle
        artist = lambda: self.main_view.currentArtist
        self.assertThat(title,
                        Eventually(Equals("Foss Yeaaaah! (Radio Edit)")))
        self.assertThat(artist, Eventually(Equals("Benjamin Kerensa")))

    def test_play_pause_library(self):
        """ Test playing and pausing a track (Music Library must exist) """

        # populate queue
        first_genre_item = self.main_view.get_first_genre_item()
        self.pointing_device.click_object(first_genre_item)

        # click back button
        back_button = self.main_view.get_back_button()
        self.pointing_device.click_object(back_button)

        self.main_view.show_toolbar()
        playbutton = self.main_view.get_play_button()

        """ Track is playing"""
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(True)))
        self.pointing_device.click_object(playbutton)

        """ Track is not playing"""
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(False)))

        """ Track is playing"""
        self.pointing_device.click_object(playbutton)
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(True)))

    def test_play_pause_now_playing(self):
        """ Test playing and pausing a track (Music Library must exist) """

        # populate queue
        first_genre_item = self.main_view.get_first_genre_item()
        self.pointing_device.click_object(first_genre_item)

        playbutton = self.main_view.get_now_playing_play_button()

        """ Track is playing"""
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(True)))
        self.pointing_device.click_object(playbutton)

        """ Track is not playing"""
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(False)))

        """ Track is playing"""
        self.pointing_device.click_object(playbutton)
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(True)))

    def test_next_previous(self):
        """ Test going to next track (Music Library must exist) """

        # populate queue
        first_genre_item = self.main_view.get_first_genre_item()
        self.pointing_device.click_object(first_genre_item)

        playbutton = self.main_view.get_now_playing_play_button()
        shufflebutton = self.main_view.get_shuffle_button()

        title = lambda: self.main_view.currentTracktitle
        artist = lambda: self.main_view.currentArtist

        orgTitle = self.main_view.currentTracktitle
        orgArtist = self.main_view.currentArtist

        #check original track
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(True)))
        logger.debug("Original Song %s, %s" % (orgTitle, orgArtist))

        """ Pause track """
        self.pointing_device.click_object(playbutton)
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(False)))

        #ensure shuffle is off
        if self.main_view.random:
            logger.debug("Turning off shuffle")
            self.pointing_device.click_object(shufflebutton)
        else:
            logger.debug("Shuffle already off")
        self.assertThat(self.main_view.random, Eventually(Equals(False)))

        """ Select next """
        #goal is to go back and forth and ensure 2 different songs
        forwardbutton = self.main_view.get_forward_button()
        self.pointing_device.click_object(forwardbutton)
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(True)))

        #ensure different song
        self.assertThat(title, Eventually(NotEquals(orgTitle)))
        self.assertThat(artist, Eventually(NotEquals(orgArtist)))
        nextTitle = self.main_view.currentTracktitle
        nextArtist = self.main_view.currentArtist
        logger.debug("Next Song %s, %s" % (nextTitle, nextArtist))

        """ Pause track """
        self.pointing_device.click_object(playbutton)
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(False)))

        """ Select previous """
        previousbutton = self.main_view.get_previous_button()
        self.pointing_device.click_object(previousbutton)
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(True)))

        #ensure we're back to original song
        self.assertThat(title, Eventually(Equals(orgTitle)))
        self.assertThat(artist, Eventually(Equals(orgArtist)))

    def test_mp3(self):
        """ Test that mp3 "plays" or at least doesn't crash on load """

        # populate queue
        first_genre_item = self.main_view.get_first_genre_item()
        self.pointing_device.click_object(first_genre_item)

        playbutton = self.main_view.get_now_playing_play_button()
        shufflebutton = self.main_view.get_shuffle_button()

        title = self.main_view.currentTracktitle
        artist = self.main_view.currentArtist

        #ensure track is playing
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(True)))

        #ensure shuffle is off
        if self.main_view.random:
            logger.debug("Turning off shuffle")
            self.pointing_device.click_object(shufflebutton)
        else:
            logger.debug("Shuffle already off")
        self.assertThat(self.main_view.random, Eventually(Equals(False)))

        """ Track is playing """
        count = 1
        #ensure track appears before looping through queue more than once
        #needs to contain test mp3 metadata and end in *.mp3
        queue = self.main_view.get_queue_track_count()
        while title != "TestMP3Title" and artist != "TestMP3Artist":
            self.assertThat(count, LessThan(queue))

            """ Pause track """
            self.pointing_device.click_object(playbutton)
            self.assertThat(self.main_view.isPlaying,
                            Eventually(Equals(False)))

            """ Select next """
            forwardbutton = self.main_view.get_forward_button()
            self.pointing_device.click_object(forwardbutton)
            self.assertThat(self.main_view.isPlaying, Eventually(Equals(True)))

            title = self.main_view.currentTracktitle
            artist = self.main_view.currentArtist
            logger.debug("Current Song %s, %s" % (title, artist))
            logger.debug("File found %s" % self.main_view.currentFile)

            count = count + 1

        #make sure mp3 plays
        self.assertThat(self.main_view.currentFile.endswith("mp3"),
                        Equals(True))
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(True)))

    def test_shuffle(self):
        """ Test shuffle (Music Library must exist) """

        # populate queue
        first_genre_item = self.main_view.get_first_genre_item()
        self.pointing_device.click_object(first_genre_item)

        """ Track is playing, shuffle is turned on"""
        shufflebutton = self.main_view.get_shuffle_button()
        forwardbutton = self.main_view.get_forward_button()
        playbutton = self.main_view.get_now_playing_play_button()
        previousbutton = self.main_view.get_previous_button()

        #play for a second, then pause
        if not self.main_view.isPlaying:
            logger.debug("Play not selected")
            self.pointing_device.click_object(playbutton)
        else:
            logger.debug("Already playing")

        self.assertThat(self.main_view.isPlaying, Eventually(Equals(True)))
        time.sleep(1)
        self.pointing_device.click_object(playbutton)
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(False)))

        count = 0
        while True:
            self.assertThat(count, LessThan(100))

            #goal is to hit next under shuffle mode
            #then verify original track is not the previous track
            #this means a true shuffle happened
            #if it doesn't try again, up to count times

            orgTitle = self.main_view.currentTracktitle
            orgArtist = self.main_view.currentArtist
            logger.debug("Original Song %s, %s" % (orgTitle, orgArtist))

            if (not self.main_view.toolbarShown):
                self.main_view.show_toolbar()

            #ensure shuffle is on
            if not self.main_view.random:
                logger.debug("Turning on shuffle")
                self.pointing_device.click_object(shufflebutton)
            else:
                logger.debug("Shuffle already on")
            self.assertThat(self.main_view.random, Eventually(Equals(True)))

            self.pointing_device.click_object(forwardbutton)
            self.assertThat(self.main_view.isPlaying,
                            Eventually(Equals(True)))
            title = self.main_view.currentTracktitle
            artist = self.main_view.currentArtist
            logger.debug("Current Song %s, %s" % (title, artist))

            #go back to previous and check against original
            #play song, then pause before switching
            time.sleep(1)
            self.pointing_device.click_object(playbutton)
            self.assertThat(self.main_view.isPlaying,
                            Eventually(Equals(False)))

            #ensure shuffle is off
            if self.main_view.random:
                logger.debug("Turning off shuffle")
                self.pointing_device.click_object(shufflebutton)
            else:
                logger.debug("Shuffle already off")
            self.assertThat(self.main_view.random, Eventually(Equals(False)))

            self.pointing_device.click_object(previousbutton)

            title = self.main_view.currentTracktitle
            artist = self.main_view.currentArtist

            if title != orgTitle and artist != orgArtist:
                #we shuffled properly
                logger.debug("Yay, shuffled %s, %s" % (title, artist))
                break
            else:
                logger.debug("Same track, no shuffle %s, %s" % (title, artist))
            count += 1

    def test_show_albums_sheet(self):
        """tests navigating to the Albums tab and displaying the album sheet"""

        artistName = "Benjamin Kerensa"

        # switch to albums tab
        self.main_view.switch_to_tab("albumstab")

        #select album
        albumartist = self.main_view.get_albums_albumartist(artistName)
        self.pointing_device.click_object(albumartist)

        #get album sheet album artist
        sheet_albumartist = self.main_view.get_album_sheet_artist()
        self.assertThat(sheet_albumartist.text, Eventually(Equals(artistName)))

        # click on close button to close album sheet
        closebutton = self.main_view.get_album_sheet_close_button()
        self.pointing_device.click_object(closebutton)
        self.assertThat(self.main_view.get_albumstab(), Not(Is(None)))

    def test_add_song_to_queue_from_albums_sheet(self):

        trackTitle = "Foss Yeaaaah! (Radio Edit)"
        artistName = "Benjamin Kerensa"

        # get number of tracks in queue before queuing a track
        initialtracksCount = self.main_view.get_queue_track_count()

        # switch to albums tab
        self.main_view.switch_to_tab("albumstab")

        #select album
        albumartist = self.main_view.get_albums_albumartist(artistName)
        self.pointing_device.click_object(albumartist)

        #get album sheet album artist
        sheet_albumartist = self.main_view.get_album_sheet_artist()
        self.assertThat(sheet_albumartist.text, Eventually(Equals(artistName)))

        #get track item to add to queue
        trackicon = self.main_view.get_album_sheet_listview_trackicon(
            trackTitle)
        self.pointing_device.click_object(trackicon)

        #click on Add to queue
        queueTrackImage = self.main_view.get_album_sheet_queuetrack_image()
        self.pointing_device.click_object(queueTrackImage)

        # verify track queue has added one to initial value
        endtracksCount = self.main_view.get_queue_track_count()
        self.assertThat(endtracksCount, Equals(initialtracksCount + 1))

        #Assert that the song added to the list is not playing
        self.assertThat(self.main_view.currentIndex,
                        Eventually(NotEquals(endtracksCount)))
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(False)))

        #verity song's metadata matches the item added to the Now Playing view
        queueArtistName = self.main_view.get_queue_now_playing_artist(
            artistName)
        self.assertThat(str(queueArtistName.text), Equals(artistName))
        queueTrackTitle = self.main_view.get_queue_now_playing_title(
            trackTitle)
        self.assertThat(str(queueTrackTitle.text), Equals(trackTitle))

        # click on close button to close album sheet
        closebutton = self.main_view.get_album_sheet_close_button()
        self.pointing_device.click_object(closebutton)
        self.assertThat(self.main_view.get_albumstab(), Not(Is(None)))

    def test_add_album_to_queue_from_albums_sheet(self):

        trackTitle = "Foss Yeaaaah! (Radio Edit)"
        artistName = "Benjamin Kerensa"

        # get number of tracks in queue before queuing a track
        initialtracksCount = self.main_view.get_queue_track_count()

        # switch to albums tab
        self.main_view.switch_to_tab("albumstab")

        #select album
        albumartist = self.main_view.get_albums_albumartist(artistName)
        self.pointing_device.click_object(albumartist)

        #get album sheet album artist
        sheet_albumartist = self.main_view.get_album_sheet_artist()
        self.assertThat(sheet_albumartist.text, Eventually(Equals(artistName)))

        #get track item to add to queue
        trackitem = self.main_view.get_album_sheet_listview_tracktitle(
            trackTitle)
        self.pointing_device.click_object(trackitem)

        #Assert that a song form the album added to the list is playing
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(True)))

        # verify track queue count is greater than initial value
        endtracksCount = self.main_view.get_queue_track_count()
        self.assertThat(endtracksCount, GreaterThan(initialtracksCount))

        #verify song's metadata matches the item added to the Now Playing view
        queueArtistName = self.main_view.get_queue_now_playing_artist(
            artistName)
        self.assertThat(str(queueArtistName.text), Equals(artistName))
        queueTrackTitle = self.main_view.get_queue_now_playing_title(
            trackTitle)
        self.assertThat(str(queueTrackTitle.text), Equals(trackTitle))
