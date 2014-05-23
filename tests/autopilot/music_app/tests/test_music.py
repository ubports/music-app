# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013, 2014 Canonical
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
        self.trackTitle = u"Gran Vals"
        self.artistName = u"Francisco Tárrega"
        self.lastTrackTitle = u"TestMP3Title"

    def populate_and_play_queue(self):
        first_genre_item = self.main_view.get_first_genre_item()
        self.pointing_device.click_object(first_genre_item)

        song = self.main_view.get_album_sheet_listview_tracktitle(
            self.trackTitle)
        self.pointing_device.click_object(song)

    def populate_and_play_queue_from_songs_tab(self):
        # switch to songs tab
        self.main_view.switch_to_tab("trackstab")

        # get track item to add to queue
        trackitem = self.main_view.get_songs_tab_tracktitle(self.trackTitle)
        self.pointing_device.click_object(trackitem)

    def turn_shuffle_off(self):
        if self.player.shuffle:
            shufflebutton = self.main_view.get_shuffle_button()
            logger.debug("Turning off shuffle")
            self.pointing_device.click_object(shufflebutton)
        else:
            logger.debug("Shuffle already off")
        self.assertThat(self.player.shuffle, Eventually(Equals(False)))

    def turn_shuffle_on(self):
        if not self.player.shuffle:
            shufflebutton = self.main_view.get_shuffle_button()
            logger.debug("Turning on shuffle")
            self.pointing_device.click_object(shufflebutton)
        else:
            logger.debug("Shuffle already on")
        self.assertThat(self.player.shuffle, Eventually(Equals(True)))

    def turn_repeat_off(self):
        if self.player.repeat:
            repeatbutton = self.main_view.get_repeat_button()
            logger.debug("Turning off repeat")
            self.pointing_device.click_object(repeatbutton)
        else:
            logger.debug("Repeat already off")
        self.assertThat(self.player.repeat, Eventually(Equals(False)))

    def turn_repeat_on(self):
        if not self.player.repeat:
            repeatbutton = self.main_view.get_repeat_button()
            logger.debug("Turning on repeat")
            self.pointing_device.click_object(repeatbutton)
        else:
            logger.debug("Repeat already on")
        self.assertThat(self.player.repeat, Eventually(Equals(True)))

    def test_reads_music_library(self):
        """ tests if the music library is populated from our
        fake mediascanner database"""

        # populate queue
        self.populate_and_play_queue_from_songs_tab()

        title = lambda: self.player.currentMetaTitle
        artist = lambda: self.player.currentMetaArtist
        self.assertThat(title, Eventually(Equals(self.trackTitle)))
        self.assertThat(artist, Eventually(Equals(self.artistName)))

    def test_play_pause_library(self):
        """ Test playing and pausing a track (Music Library must exist) """

        # get number of tracks in queue before queuing a track
        initialtracksCount = self.main_view.get_queue_track_count()

        self.main_view.add_to_queue_from_albums_tab_album_sheet(
            self.artistName, self.trackTitle)

        # verify track queue has added one to initial value
        endtracksCount = self.main_view.get_queue_track_count()
        self.assertThat(endtracksCount, Equals(initialtracksCount + 1))

        #Assert that the song added to the list is not playing
        self.assertThat(self.player.currentIndex,
                        Eventually(NotEquals(endtracksCount)))
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        #verify song's metadata matches the item added to the Now Playing view
        queueArtistName = self.main_view.get_queue_now_playing_artist(
            self.artistName)
        self.assertThat(queueArtistName.text, Equals(self.artistName))
        queueTrackTitle = self.main_view.get_queue_now_playing_title(
            self.trackTitle)
        self.assertThat(queueTrackTitle.text, Equals(self.trackTitle))

        # click on close button to close album sheet
        closebutton = self.main_view.get_album_sheet_close_button()
        self.pointing_device.click_object(closebutton)
        self.assertThat(self.main_view.get_albumstab(), Not(Is(None)))

        if self.main_view.wideAspect:
            play_button = self.main_view.get_now_playing_play_button()
        else:
            play_button = self.main_view.get_play_button()
            self.main_view.show_toolbar()

        """ Track is playing"""
        self.pointing_device.click_object(play_button)
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

        """ Track is not playing"""
        self.pointing_device.click_object(play_button)
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

    def test_play_pause_now_playing(self):
        """ Test playing and pausing a track (Music Library must exist) """

        # populate queue
        self.populate_and_play_queue_from_songs_tab()

        playbutton = self.main_view.get_now_playing_play_button()

        """ Track is playing"""
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))
        self.pointing_device.click_object(playbutton)

        """ Track is not playing"""
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        """ Track is playing"""
        self.pointing_device.click_object(playbutton)
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

    def test_next_previous(self):
        """ Test going to next track (Music Library must exist) """

        # populate queue
        self.populate_and_play_queue_from_songs_tab()

        playbutton = self.main_view.get_now_playing_play_button()

        title = lambda: self.player.currentMetaTitle
        artist = lambda: self.player.currentMetaArtist

        orgTitle = self.player.currentMetaTitle
        orgArtist = self.player.currentMetaArtist

        #check original track
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))
        logger.debug("Original Song %s, %s" % (orgTitle, orgArtist))

        """ Pause track """
        self.pointing_device.click_object(playbutton)
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        self.turn_shuffle_off()

        """ Select next """
        #goal is to go back and forth and ensure 2 different songs
        forwardbutton = self.main_view.get_forward_button()
        self.pointing_device.click_object(forwardbutton)
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

        """ Pause track """
        self.pointing_device.click_object(playbutton)
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        #ensure different song
        self.assertThat(title, Eventually(NotEquals(orgTitle)))
        self.assertThat(artist, Eventually(NotEquals(orgArtist)))
        nextTitle = self.player.currentMetaTitle
        nextArtist = self.player.currentMetaArtist
        logger.debug("Next Song %s, %s" % (nextTitle, nextArtist))

        """ Select previous """
        previousbutton = self.main_view.get_previous_button()
        self.pointing_device.click_object(previousbutton)
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

        """ Pause track """
        self.pointing_device.click_object(playbutton)
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        #ensure we're back to original song
        self.assertThat(title, Eventually(Equals(orgTitle)))
        self.assertThat(artist, Eventually(Equals(orgArtist)))

    def test_mp3(self):
        """ Test that mp3 "plays" or at least doesn't crash on load """

        # populate queue
        self.populate_and_play_queue_from_songs_tab()

        playbutton = self.main_view.get_now_playing_play_button()

        title = self.player.currentMetaTitle
        artist = self.player.currentMetaArtist

        self.turn_shuffle_off()

        """ Track is playing """
        count = 1
        #ensure track appears before looping through queue more than once
        #needs to contain test mp3 metadata and end in *.mp3
        queue = self.main_view.get_queue_track_count()
        while title != "TestMP3Title" and artist != "TestMP3Artist":
            self.assertThat(count, LessThan(queue))

            """ Select next """
            forwardbutton = self.main_view.get_forward_button()
            self.pointing_device.click_object(forwardbutton)

            """ Pause track """
            self.pointing_device.click_object(playbutton)
            self.assertThat(self.player.isPlaying,
                            Eventually(Equals(False)))

            title = self.player.currentMetaTitle
            artist = self.player.currentMetaArtist
            logger.debug("Current Song %s, %s" % (title, artist))
            logger.debug("File found %s" % self.player.currentMetaFile)

            count = count + 1

        #make sure mp3 plays
        self.assertThat(self.player.source.endswith("mp3"),
                        Equals(True))
        self.pointing_device.click_object(playbutton)
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

    def test_shuffle(self):
        """ Test shuffle (Music Library must exist) """

        # populate queue
        self.populate_and_play_queue_from_songs_tab()

        """ Track is playing, shuffle is turned on"""
        forwardbutton = self.main_view.get_forward_button()
        playbutton = self.main_view.get_now_playing_play_button()
        previousbutton = self.main_view.get_previous_button()

        #play for a second, then pause
        if not self.player.isPlaying:
            logger.debug("Play not selected")
            self.pointing_device.click_object(playbutton)
        else:
            logger.debug("Already playing")

        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))
        time.sleep(1)
        self.pointing_device.click_object(playbutton)
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        count = 0
        while True:
            self.assertThat(count, LessThan(100))

            #goal is to hit next under shuffle mode
            #then verify original track is not the previous track
            #this means a true shuffle happened
            #if it doesn't try again, up to count times

            orgTitle = self.player.currentMetaTitle
            orgArtist = self.player.currentMetaArtist
            logger.debug("Original Song %s, %s" % (orgTitle, orgArtist))

            if (not self.main_view.toolbarShown):
                self.main_view.show_toolbar()

            self.turn_shuffle_on()

            self.pointing_device.click_object(forwardbutton)
            self.assertThat(self.player.isPlaying,
                            Eventually(Equals(True)))
            title = self.player.currentMetaTitle
            artist = self.player.currentMetaArtist
            logger.debug("Current Song %s, %s" % (title, artist))

            #go back to previous and check against original
            #play song, then pause before switching
            time.sleep(1)
            self.pointing_device.click_object(playbutton)
            self.assertThat(self.player.isPlaying,
                            Eventually(Equals(False)))

            self.turn_shuffle_off()

            self.pointing_device.click_object(previousbutton)

            title = self.player.currentMetaTitle
            artist = self.player.currentMetaArtist

            if title != orgTitle and artist != orgArtist:
                #we shuffled properly
                logger.debug("Yay, shuffled %s, %s" % (title, artist))
                break
            else:
                logger.debug("Same track, no shuffle %s, %s" % (title, artist))
            count += 1

    def test_show_albums_sheet(self):
        """tests navigating to the Albums tab and displaying the album sheet"""

        # switch to albums tab
        self.main_view.switch_to_tab("albumstab")

        #select album
        albumartist = self.main_view.get_albums_albumartist(self.artistName)
        self.pointing_device.click_object(albumartist)

        #get album sheet album artist
        sheet_albumartist = self.main_view.get_album_sheet_artist()
        self.assertThat(sheet_albumartist.text, Equals(self.artistName))

        # click on close button to close album sheet
        closebutton = self.main_view.get_album_sheet_close_button()
        self.pointing_device.click_object(closebutton)
        self.assertThat(self.main_view.get_albumstab(), Not(Is(None)))

    def test_add_song_to_queue_from_albums_sheet(self):
        """tests navigating to the Albums tab and adding a song to queue"""

        # get number of tracks in queue before queuing a track
        initialtracksCount = self.main_view.get_queue_track_count()

        self.main_view.add_to_queue_from_albums_tab_album_sheet(
            self.artistName, self.trackTitle)

        # verify track queue has added one to initial value
        endtracksCount = self.main_view.get_queue_track_count()
        self.assertThat(endtracksCount, Equals(initialtracksCount + 1))

        #Assert that the song added to the list is not playing
        self.assertThat(self.player.currentIndex,
                        Eventually(NotEquals(endtracksCount)))
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        #verify song's metadata matches the item added to the Now Playing view
        queueArtistName = self.main_view.get_queue_now_playing_artist(
            self.artistName)
        self.assertThat(queueArtistName.text, Equals(self.artistName))
        queueTrackTitle = self.main_view.get_queue_now_playing_title(
            self.trackTitle)
        self.assertThat(queueTrackTitle.text, Equals(self.trackTitle))

        # click on close button to close album sheet
        closebutton = self.main_view.get_album_sheet_close_button()
        self.pointing_device.click_object(closebutton)
        self.assertThat(self.main_view.get_albumstab(), Not(Is(None)))

    def test_add_songs_to_queue_from_songs_tab_and_play(self):
        """tests navigating to the Songs tab and adding the library to the
           queue with the selected item being played. """

        # get number of tracks in queue before queuing a track
        initialtracksCount = self.main_view.get_queue_track_count()

        # populate queue
        self.populate_and_play_queue_from_songs_tab()

        # verify track queue has added all songs to initial value
        endtracksCount = self.main_view.get_queue_track_count()
        self.assertThat(endtracksCount, Equals(initialtracksCount + 3))

        # Assert that the song added to the list is playing
        self.assertThat(self.player.currentIndex,
                        Eventually(NotEquals(endtracksCount)))
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

        # verify song's metadata matches the item added to the Now Playing view
        queueArtistName = self.main_view.get_queue_now_playing_artist(
            self.artistName)
        self.assertThat(queueArtistName.text, Equals(self.artistName))
        queueTrackTitle = self.main_view.get_queue_now_playing_title(
            self.trackTitle)
        self.assertThat(queueTrackTitle.text, Equals(self.trackTitle))

    def test_add_song_to_queue_from_songs_tab(self):
        """tests navigating to the Songs tab and adding a song from the library
           to the queue via the expandable list view item. """

        # get number of tracks in queue before queuing a track
        initialtracksCount = self.main_view.get_queue_track_count()

        # switch to songs tab
        self.main_view.switch_to_tab("trackstab")

        # get track item to add to queue
        trackitem = self.main_view.get_songs_tab_trackimage(self.trackTitle)
        self.pointing_device.click_object(trackitem)
        addtoqueueLabel = self.main_view.get_songs_tab_add_to_queue_label()
        self.pointing_device.click_object(addtoqueueLabel)

        # verify track queue has added all songs to initial value
        endtracksCount = self.main_view.get_queue_track_count()
        self.assertThat(endtracksCount, Equals(initialtracksCount + 1))

        # Assert that the song added to the list is not playing
        self.assertThat(self.player.currentIndex,
                        Eventually(NotEquals(endtracksCount)))
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        # verify song's metadata matches the item added to the Now Playing view
        queueArtistName = self.main_view.get_queue_now_playing_artist(
            self.artistName)
        self.assertThat(queueArtistName.text, Equals(self.artistName))
        queueTrackTitle = self.main_view.get_queue_now_playing_title(
            self.trackTitle)
        self.assertThat(queueTrackTitle.text, Equals(self.trackTitle))

    def test_create_playlist_from_songs_tab(self):
        """tests navigating to the Songs tab and creating a playlist by
           selecting a song to add it to a new playlist. """

        # switch to songs tab
        self.main_view.switch_to_tab("trackstab")

        # get track item to add to queue
        trackitem = self.main_view.get_songs_tab_trackimage(self.trackTitle)
        self.pointing_device.click_object(trackitem)
        addtoplaylistLbl = self.main_view.get_songs_tab_add_to_playlist_label()
        self.pointing_device.click_object(addtoplaylistLbl)

        # get initial list view playlist count
        playlist_count = self.main_view.get_addtoplaylistview()[0].count

        # click on New playlist button
        newplaylistButton = self.main_view.get_newplaylistButton()[0]
        self.pointing_device.click_object(newplaylistButton)

        # input playlist name
        playlistNameFld = self.main_view.get_newPlaylistDialog_name_textfield()
        self.pointing_device.click_object(playlistNameFld)
        playlistNameFld.focus.wait_for(True)
        self.keyboard.type("myPlaylist")

        # click on get_newPlaylistDialog create Button
        createButton = self.main_view.get_newPlaylistDialog_createButton()
        self.pointing_device.click_object(createButton)

        # verify playlist has been sucessfully created
        palylist_final_count = self.main_view.get_addtoplaylistview()[0].count
        self.assertThat(palylist_final_count, Equals(playlist_count + 1))
        playlist = self.main_view.get_playlistname("myPlaylist")
        self.assertThat(playlist, Not(Is(None)))

        # select playlist to add song to
        self.pointing_device.click_object(playlist)

        # verify song has been added to playlist
        playlistslist = self.main_view.get_playlistslist()
        self.assertThat(playlistslist.count, Equals(1))

    def test_artists_tab_album(self):
        """tests navigating to the Artists tab and playing an album"""

        # get number of tracks in queue before queuing a track
        initialtracksCount = self.main_view.get_queue_track_count()

        # switch to artists tab
        self.main_view.switch_to_tab("artiststab")

        #select artist
        artist = self.main_view.get_artists_artist(self.artistName)
        self.pointing_device.click_object(artist)

        #get album sheet album artist
        sheet_albumartist = self.main_view.get_artist_sheet_artist()
        self.assertThat(sheet_albumartist.text, Equals(self.artistName))

        # click on album to shows the artists
        sheet_albumartist = self.main_view.get_artist_sheet_artist_cover()
        self.pointing_device.click_object(sheet_albumartist)

        #get song sheet album artist
        sheet_albumartist = self.main_view.get_album_sheet_artist()
        self.assertThat(sheet_albumartist.text, Equals(self.artistName))

        # click on song to populate queue and start playing
        self.pointing_device.click_object(sheet_albumartist)

        #select artist
        track = self.main_view.get_album_sheet_listview_tracktitle(
            self.trackTitle)
        self.pointing_device.click_object(track)

        # verify track queue has added all songs to initial value
        endtracksCount = self.main_view.get_queue_track_count()
        self.assertThat(endtracksCount, Equals(initialtracksCount + 3))

        # Assert that the song added to the list is playing
        self.assertThat(self.player.currentIndex,
                        Eventually(NotEquals(endtracksCount)))
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

        # verify song's metadata matches the item added to the Now Playing view
        queueArtistName = self.main_view.get_queue_now_playing_artist(
            self.artistName)
        self.assertThat(queueArtistName.text, Equals(self.artistName))
        queueTrackTitle = self.main_view.get_queue_now_playing_title(
            self.trackTitle)
        self.assertThat(queueTrackTitle.text, Equals(self.trackTitle))

    def test_swipe_to_delete_song(self):
        """tests navigating to the Now Playing queue, swiping to delete a
        track, and confirming the delete action. """

        # populate queue
        self.populate_and_play_queue_from_songs_tab()

        # get initial queue count
        initialqueueCount = self.main_view.get_queue_track_count()

        # get song to delete
        artistToDelete = self.main_view.get_queue_now_playing_artist(
            self.artistName)
        musicnowplayingpage = self.main_view.get_MusicNowPlaying_page()

        # get coordinates to delete song
        startX = int(musicnowplayingpage.globalRect[0] +
                     musicnowplayingpage.width * 0.30)
        stopX = int(musicnowplayingpage.globalRect[0] +
                    musicnowplayingpage.width)
        lineY = int(artistToDelete.globalRect[1])

        # swipe to remove song
        self.pointing_device.move(startX, lineY)
        self.pointing_device.drag(startX, lineY, stopX, lineY)

        # click on delete icon/label to confirm removal
        swipedeleteicon = self.main_view.get_swipedelete_icon()
        self.pointing_device.click_object(swipedeleteicon)

        # verify song has been deleted
        finalqueueCount = self.main_view.get_queue_track_count()
        self.assertThat(finalqueueCount, Equals(initialqueueCount - 1))

    def test_playback_stops_when_last_song_ends_and_repeat_off(self):
        """Check that playback stops when the last song in the queue ends"""

        # populate queue
        self.populate_and_play_queue_from_songs_tab()

        self.turn_shuffle_off()
        self.turn_repeat_off()

        num_tracks = self.main_view.get_queue_track_count()

        #Skip through all songs in queue, stopping on last one.
        forward_button = self.main_view.get_forward_button()
        for count in range(0, num_tracks - 1):
            self.pointing_device.click_object(forward_button)

        #When the last song ends, playback should stop
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

    def test_playback_repeats_when_last_song_ends_and_repeat_on(self):
        """With repeat on, the 1st song should play after the last one ends"""

        # populate queue
        self.populate_and_play_queue_from_songs_tab()

        self.turn_shuffle_off()
        self.turn_repeat_on()

        num_titles = self.main_view.get_queue_track_count()
        #Skip through all songs in queue, stopping on last one.
        forward_button = self.main_view.get_forward_button()
        for count in range(0, num_titles - 1):
            self.pointing_device.click_object(forward_button)

        #Make sure we loop back to first song after last song ends
        actual_title = lambda: self.player.currentMetaTitle
        self.assertThat(actual_title, Eventually(Equals(self.trackTitle)))
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

    def test_pressing_next_from_last_song_plays_first_when_repeat_on(self):
        """With repeat on, skipping the last song jumps to the first track"""

        # populate queue
        self.populate_and_play_queue_from_songs_tab()

        self.turn_shuffle_off()
        self.turn_repeat_on()

        num_titles = self.main_view.get_queue_track_count()
        #Skip through all songs in queue, INCLUDING last one.
        forward_button = self.main_view.get_forward_button()
        for count in range(0, num_titles - 1):
            self.pointing_device.click_object(forward_button)

        actual_title = lambda: self.player.currentMetaTitle
        self.assertThat(actual_title, Eventually(Equals(self.trackTitle)))
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

    def test_pressing_prev_from_first_song_plays_last_when_repeat_on(self):
        """With repeat on, 'previous' from the 1st song plays the last one."""

        # populate queue
        self.populate_and_play_queue_from_songs_tab()

        self.turn_shuffle_off()
        self.turn_repeat_on()

        prev_button = self.main_view.get_previous_button()
        initial_song = self.player.currentMetaTitle
        self.pointing_device.click_object(prev_button)
        #If we're far enough into a song, pressing prev just takes us to the
        #beginning of that track.  In that case, hit prev again to actually
        #skip over the track.
        if self.player.currentMetaTitle == initial_song:
            self.pointing_device.click_object(prev_button)

        actual_title = lambda: self.player.currentMetaTitle
        self.assertThat(actual_title, Eventually(Equals(self.lastTrackTitle)))
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))
