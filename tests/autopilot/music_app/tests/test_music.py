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


from music_app.tests import MusicAppTestCase

logger = logging.getLogger(__name__)


class TestMainWindow(MusicAppTestCase):

    def setUp(self):
        super(TestMainWindow, self).setUp()

        self.trackTitle = u"Gran Vals"
        self.artistName = u"Francisco Tárrega"
        self.lastTrackTitle = u"TestMP3Title"

    @property
    def main_view(self):
        return self.app.main_view

    @property
    def player(self):
        return self.app.player

    @property
    def pointing_device(self):
        return self.app.app.pointing_device

    def test_reads_music_library(self):
        """ tests if the music library is populated from our
        fake mediascanner database"""

        self.app.populate_queue()  # populate queue

        title = lambda: self.player.currentMetaTitle
        artist = lambda: self.player.currentMetaArtist
        self.assertThat(title, Eventually(Equals(self.trackTitle)))
        self.assertThat(artist, Eventually(Equals(self.artistName)))

    def test_play_pause_library(self):
        """ Test playing and pausing a track (Music Library must exist) """

        now_playing_page = self.app.get_now_playing_page()
        toolbar = self.app.get_toolbar()

        # get number of tracks in queue before queuing a track
        initial_tracks_count = now_playing_page.get_count()

        self.main_view.add_to_queue_from_albums_tab_album_page(
            self.artistName, self.trackTitle)

        # verify track queue has added one to initial value
        self.assertThat(now_playing_page.get_count(),
                        Eventually(Equals(initial_tracks_count + 1)))

        end_tracks_count = now_playing_page.get_count()

        # Assert that the song added to the list is not playing
        self.assertThat(self.player.currentIndex,
                        Eventually(NotEquals(end_tracks_count)))
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        # verify song's metadata matches the item added to the Now Playing view
        queueArtistName = self.main_view.get_queue_now_playing_artist(
            self.artistName)
        self.assertThat(queueArtistName.text, Equals(self.artistName))
        queueTrackTitle = self.main_view.get_queue_now_playing_title(
            self.trackTitle)
        self.assertThat(queueTrackTitle.text, Equals(self.trackTitle))

        # click on close button to close the page
        self.main_view.go_back()

        """ Track is playing"""
        if self.main_view.wideAspect:
            toolbar.click_full_play_button()
        else:
            if not toolbar.opened:
                toolbar.show()

            toolbar.click_expanded_play_button()

        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

        """ Track is not playing"""
        if self.main_view.wideAspect:
            toolbar.click_full_play_button()
        else:
            if not toolbar.opened:
                toolbar.show()

            toolbar.click_expanded_play_button()

        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

    def test_play_pause_now_playing(self):
        """ Test playing and pausing a track (Music Library must exist) """

        self.app.populate_queue()  # populate queue

        toolbar = self.app.get_toolbar()

        """ Track is playing"""
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))
        toolbar.click_full_play_button()

        """ Track is not playing"""
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        """ Track is playing"""
        toolbar.click_full_play_button()
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

    def test_next_previous(self):
        """ Test going to next track (Music Library must exist) """

        self.app.populate_queue()  # populate queue

        now_playing_page = self.app.get_now_playing_page()
        toolbar = self.app.get_toolbar()

        title = lambda: self.player.currentMetaTitle
        artist = lambda: self.player.currentMetaArtist

        orgTitle = self.player.currentMetaTitle
        orgArtist = self.player.currentMetaArtist

        # check original track
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))
        logger.debug("Original Song %s, %s" % (orgTitle, orgArtist))

        """ Pause track """
        toolbar.click_full_play_button()
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        now_playing_page.set_shuffle(False)

        """ Select next """
        # goal is to go back and forth and ensure 2 different songs
        toolbar.click_full_forward_button()
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

        """ Pause track """
        toolbar.click_full_play_button()
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        # ensure different song
        self.assertThat(title, Eventually(NotEquals(orgTitle)))
        self.assertThat(artist, Eventually(NotEquals(orgArtist)))
        nextTitle = self.player.currentMetaTitle
        nextArtist = self.player.currentMetaArtist
        logger.debug("Next Song %s, %s" % (nextTitle, nextArtist))

        """ Seek to 0 """
        self.main_view.seek_to_0()  # TODO: put in helper in future

        """ Select previous """
        toolbar.click_full_previous_button()
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

        """ Pause track """
        toolbar.click_full_play_button()
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        # ensure we're back to original song
        self.assertThat(title, Eventually(Equals(orgTitle)))
        self.assertThat(artist, Eventually(Equals(orgArtist)))

    def test_mp3(self):
        """ Test that mp3 "plays" or at least doesn't crash on load """

        self.app.populate_queue()  # populate queue

        now_playing_page = self.app.get_now_playing_page()
        toolbar = self.app.get_toolbar()

        title = self.player.currentMetaTitle
        artist = self.player.currentMetaArtist

        now_playing_page.set_shuffle(False)

        """ Track is playing """
        count = 1

        # ensure track appears before looping through queue more than once
        # needs to contain test mp3 metadata and end in *.mp3
        queue = now_playing_page.get_count()

        while title != "TestMP3Title" and artist != "TestMP3Artist":
            self.assertThat(count, LessThan(queue))

            """ Select next """
            toolbar.click_full_forward_button()

            """ Pause track """
            toolbar.click_full_play_button()
            self.assertThat(self.player.isPlaying,
                            Eventually(Equals(False)))

            title = self.player.currentMetaTitle
            artist = self.player.currentMetaArtist
            logger.debug("Current Song %s, %s" % (title, artist))
            logger.debug("File found %s" % self.player.currentMetaFile)

            count = count + 1

        # make sure mp3 plays
        self.assertThat(self.player.source.endswith("mp3"),
                        Equals(True))
        toolbar.click_full_play_button()
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

    def test_shuffle(self):
        """ Test shuffle (Music Library must exist) """

        self.app.populate_queue()  # populate queue

        """ Track is playing, shuffle is turned on"""
        now_playing_page = self.app.get_now_playing_page()
        toolbar = self.app.get_toolbar()

        # play for a second, then pause
        if not self.player.isPlaying:
            logger.debug("Play not selected")
            toolbar.click_full_play_button()
        else:
            logger.debug("Already playing")

        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))
        time.sleep(1)
        toolbar.click_full_play_button()
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        count = 0
        while True:
            self.assertThat(count, LessThan(100))

            # goal is to hit next under shuffle mode
            # then verify original track is not the previous track
            # this means a true shuffle happened
            # if it doesn't try again, up to count times

            orgTitle = self.player.currentMetaTitle
            orgArtist = self.player.currentMetaArtist
            logger.debug("Original Song %s, %s" % (orgTitle, orgArtist))

            if (not toolbar.opened):
                toolbar.show()

            now_playing_page.set_shuffle(True)

            toolbar.click_full_forward_button()
            self.assertThat(self.player.isPlaying,
                            Eventually(Equals(True)))
            title = self.player.currentMetaTitle
            artist = self.player.currentMetaArtist
            logger.debug("Current Song %s, %s" % (title, artist))

            # go back to previous and check against original
            # play song, then pause before switching
            time.sleep(1)
            toolbar.click_full_play_button()
            self.assertThat(self.player.isPlaying,
                            Eventually(Equals(False)))

            now_playing_page.set_shuffle(False)

            toolbar.click_full_previous_button()

            title = self.player.currentMetaTitle
            artist = self.player.currentMetaArtist

            if title != orgTitle and artist != orgArtist:
                # we shuffled properly
                logger.debug("Yay, shuffled %s, %s" % (title, artist))
                break
            else:
                logger.debug("Same track, no shuffle %s, %s" % (title, artist))

            count += 1

    def test_show_albums_page(self):
        """tests navigating to the Albums tab and displaying the album page"""

        # switch to albums tab
        self.main_view.switch_to_tab("albumstab")

        # select album
        albumartist = self.main_view.get_albums_albumartist(self.artistName)
        self.pointing_device.click_object(albumartist)

        # get album page album artist
        songs_page_albumartist = self.main_view.get_songs_page_artist()
        self.assertThat(songs_page_albumartist.text, Equals(self.artistName))

        # click on close button to close album page
        self.main_view.go_back()
        self.assertThat(self.main_view.get_albumstab(), Not(Is(None)))

    def test_add_song_to_queue_from_albums_page(self):
        """tests navigating to the Albums tab and adding a song to queue"""

        now_playing_page = self.app.get_now_playing_page()

        # get number of tracks in queue before queuing a track
        initial_tracks_count = now_playing_page.get_count()

        self.main_view.add_to_queue_from_albums_tab_album_page(
            self.artistName, self.trackTitle)

        # verify track queue has added one to initial value
        self.assertThat(now_playing_page.get_count(),
                        Eventually(Equals(initial_tracks_count + 1)))

        # Assert that the song added to the list is not playing
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        # verify song's metadata matches the item added to the Now Playing view
        queueArtistName = self.main_view.get_queue_now_playing_artist(
            self.artistName)
        self.assertThat(queueArtistName.text, Equals(self.artistName))
        queueTrackTitle = self.main_view.get_queue_now_playing_title(
            self.trackTitle)
        self.assertThat(queueTrackTitle.text, Equals(self.trackTitle))

        # click on close button to close album page
        self.main_view.go_back()
        self.assertThat(self.main_view.get_albumstab(), Not(Is(None)))

    def test_add_songs_to_queue_from_songs_tab_and_play(self):
        """tests navigating to the Songs tab and adding the library to the
           queue with the selected item being played. """

        now_playing_page = self.app.get_now_playing_page()

        # get number of tracks in queue before queuing a track
        initial_tracks_count = now_playing_page.get_count()

        self.app.populate_queue()  # populate queue

        # get now playing again as it has moved
        now_playing_page = self.app.get_now_playing_page()

        # verify track queue has added all songs to initial value
        self.assertThat(now_playing_page.get_count(),
                        Equals(initial_tracks_count + 3))

        # Assert that the song added to the list is playing
        self.assertThat(self.player.currentIndex,
                        Eventually(NotEquals(now_playing_page.get_count())))
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

        now_playing_page = self.app.get_now_playing_page()

        # get number of tracks in queue before queuing a track
        initial_tracks_count = now_playing_page.get_count()

        # switch to songs tab
        self.main_view.switch_to_tab("tracksTab")

        # get track item to swipe and queue
        trackitem = self.main_view.get_songs_tab_tracktitle(self.trackTitle)
        songspage = self.main_view.get_tracks_tab_listview()

        # get coordinates to swipe
        start_x = int(songspage.globalRect.x +
                      (songspage.globalRect.width * 0.9))
        stop_x = int(songspage.globalRect.x)
        line_y = int(trackitem.globalRect.y)

        # swipe to add to queue
        self.pointing_device.move(start_x, line_y)
        self.pointing_device.drag(start_x, line_y, stop_x, line_y)

        # click on add to queue
        queueaction = self.main_view.get_add_to_queue_action()
        self.pointing_device.click_object(queueaction)

        # verify track queue has added all songs to initial value
        self.assertThat(now_playing_page.get_count(),
                        Eventually(Equals(initial_tracks_count + 1)))

        # Assert that the song added to the list is not playing
        self.assertThat(self.player.currentIndex,
                        Eventually(NotEquals(now_playing_page.get_count())))
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
        self.main_view.switch_to_tab("tracksTab")

        # get track item to swipe and queue
        trackitem = self.main_view.get_songs_tab_tracktitle(self.trackTitle)
        songspage = self.main_view.get_tracks_tab_listview()

        # get coordinates to swipe
        start_x = int(songspage.globalRect.x +
                      (songspage.globalRect.width * 0.9))
        stop_x = int(songspage.globalRect.x)
        line_y = int(trackitem.globalRect.y)

        # swipe to add to queue
        self.pointing_device.move(start_x, line_y)
        self.pointing_device.drag(start_x, line_y, stop_x, line_y)

        # click on add to playlist
        playlistaction = self.main_view.get_add_to_playlist_action()
        self.pointing_device.click_object(playlistaction)

        # Wait for animations to complete
        playlistaction.primed.wait_for(False)

        # get initial list view playlist count
        playlist_count = self.main_view.get_addtoplaylistview().count

        # click on New playlist button in header
        self.main_view.tap_new_playlist_action()

        # input playlist name
        playlistNameFld = self.main_view.get_newPlaylistDialog_name_textfield()
        self.pointing_device.click_object(playlistNameFld)
        playlistNameFld.focus.wait_for(True)
        self.keyboard.type("myPlaylist")

        # click on get_newPlaylistDialog create Button
        createButton = self.main_view.get_newPlaylistDialog_createButton()
        self.pointing_device.click_object(createButton)

        # verify playlist has been sucessfully created
        palylist_final_count = self.main_view.get_addtoplaylistview().count
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

        now_playing_page = self.app.get_now_playing_page()

        # get number of tracks in queue before queuing a track
        initial_tracks_count = now_playing_page.get_count()

        # switch to artists tab
        self.main_view.switch_to_tab("artiststab")

        # select artist
        artist = self.main_view.get_artists_artist(self.artistName)
        self.pointing_device.click_object(artist)

        # get album page album artist
        page_albumartist = self.main_view.get_artist_page_artist()
        self.assertThat(page_albumartist.text, Equals(self.artistName))

        # click on album to shows the artists
        albumartist_cover = self.main_view.get_artist_page_artist_cover()
        self.pointing_device.click_object(albumartist_cover)

        # get song page album artist
        songs_page_albumartist = self.main_view.get_songs_page_artist()
        self.assertThat(songs_page_albumartist.text, Equals(self.artistName))

        # click on song to populate queue and start playing
        self.pointing_device.click_object(songs_page_albumartist)

        # select artist
        track = self.main_view.get_songs_page_listview_tracktitle(
            self.trackTitle)
        self.pointing_device.click_object(track)

        # get now playing again as it has moved
        now_playing_page = self.app.get_now_playing_page()

        # verify track queue has added all songs to initial value
        self.assertThat(now_playing_page.get_count(),
                        Equals(initial_tracks_count + 2))

        # Assert that the song added to the list is playing
        self.assertThat(self.player.currentIndex,
                        Eventually(NotEquals(now_playing_page.get_count())))
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

        self.app.populate_queue()  # populate queue

        now_playing_page = self.app.get_now_playing_page()

        # get initial queue count
        initial_queue_count = now_playing_page.get_count()

        # get song to delete
        track = now_playing_page.get_track(0)

        # TODO: make ListItemWithActions helper for swiping
        # get coordinates to delete song
        start_x = int(now_playing_page.globalRect.x +
                      now_playing_page.globalRect.width * 0.30)
        stop_x = int(now_playing_page.globalRect.x +
                     now_playing_page.globalRect.width * 0.90)
        line_y = int(track.globalRect.y) + int(track.height / 2)

        # swipe to remove song
        self.pointing_device.move(start_x, line_y)
        self.pointing_device.drag(start_x, line_y, stop_x, line_y)

        # click on delete icon/label to confirm removal
        swipedeleteicon = self.main_view.get_swipedelete_icon()
        self.pointing_device.click_object(swipedeleteicon)

        # verify song has been deleted
        self.assertThat(now_playing_page.get_count(),
                        Eventually(Equals(initial_queue_count - 1)))

    def test_playback_stops_when_last_song_ends_and_repeat_off(self):
        """Check that playback stops when the last song in the queue ends"""

        self.app.populate_queue()  # populate queue

        now_playing_page = self.app.get_now_playing_page()
        toolbar = self.app.get_toolbar()

        now_playing_page.set_shuffle(False)
        now_playing_page.set_repeat(False)

        # Skip through all songs in queue, stopping on last one.
        for count in range(0, now_playing_page.get_count() - 1):
            toolbar.click_full_forward_button()

        # When the last song ends, playback should stop
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

    def test_playback_repeats_when_last_song_ends_and_repeat_on(self):
        """With repeat on, the 1st song should play after the last one ends"""

        self.app.populate_queue()  # populate queue

        now_playing_page = self.app.get_now_playing_page()
        toolbar = self.app.get_toolbar()

        now_playing_page.set_shuffle(False)
        now_playing_page.set_repeat(True)

        # Skip through all songs in queue, stopping on last one.
        for count in range(0, now_playing_page.get_count() - 1):
            toolbar.click_full_forward_button()

        # Make sure we loop back to first song after last song ends
        actual_title = lambda: self.player.currentMetaTitle
        self.assertThat(actual_title, Eventually(Equals(self.trackTitle)))
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

    def test_pressing_next_from_last_song_plays_first_when_repeat_on(self):
        """With repeat on, skipping the last song jumps to the first track"""

        self.app.populate_queue()  # populate queue

        now_playing_page = self.app.get_now_playing_page()
        toolbar = self.app.get_toolbar()

        now_playing_page.set_shuffle(False)
        now_playing_page.set_repeat(True)

        # Skip through all songs in queue, INCLUDING last one.
        for count in range(0, now_playing_page.get_count() - 1):
            toolbar.click_full_forward_button()

        actual_title = lambda: self.player.currentMetaTitle
        self.assertThat(actual_title, Eventually(Equals(self.trackTitle)))
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

    def test_pressing_prev_from_first_song_plays_last_when_repeat_on(self):
        """With repeat on, 'previous' from the 1st song plays the last one."""

        self.app.populate_queue()  # populate queue

        now_playing_page = self.app.get_now_playing_page()
        toolbar = self.app.get_toolbar()

        now_playing_page.set_shuffle(False)
        now_playing_page.set_repeat(True)

        initial_song = self.player.currentMetaTitle
        toolbar.click_full_previous_button()

        # If we're far enough into a song, pressing prev just takes us to the
        # beginning of that track.  In that case, hit prev again to actually
        # skip over the track.
        if self.player.currentMetaTitle == initial_song:
            toolbar.click_full_previous_button()

        actual_title = lambda: self.player.currentMetaTitle
        self.assertThat(actual_title, Eventually(Equals(self.lastTrackTitle)))
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))
