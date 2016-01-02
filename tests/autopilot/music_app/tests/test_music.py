# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013, 2014, 2015 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Music app autopilot tests."""

from __future__ import absolute_import

import logging
from autopilot.matchers import Eventually
from testtools.matchers import Equals, GreaterThan, LessThan, NotEquals


from music_app.tests import MusicAppTestCase

logger = logging.getLogger(__name__)


class TestMainWindow(MusicAppTestCase):

    def setUp(self):
        super(TestMainWindow, self).setUp()

        # metadata for test tracks sorted by title
        # tests should sort themselves if they require by artist/album
        self.tracks = [
            {
                "album": "",
                "artist": u"Francisco Tárrega",
                "source": "1.ogg",
                "title": u"Gran Vals"
            },
            {
                "album": "",
                "artist": "Josh Woodward",
                "source": "2.ogg",
                "title": "Swansong"
            },
            {
                "album": "TestMP3Album",
                "artist": "TestMP3Artist",
                "source": "3.mp3",
                "title": "TestMP3Title",
            }
        ]

        # Skip the walkthrough for every test
        self.app.get_walkthrough_page().skip()

    @property
    def player(self):
        return self.app.player

    def test_reads_music_library(self):
        """ tests if the music library is populated from our
        fake mediascanner database"""

        self.app.populate_queue()  # populate queue

        # Check current meta data is correct
        self.assertThat(self.player.currentMeta.title,
                        Eventually(Equals(self.tracks[0]["title"])))
        self.assertThat(self.player.currentMeta.author,
                        Eventually(Equals(self.tracks[0]["artist"])))

    def test_play_pause_library(self):
        """ Test playing and pausing a track (Music Library must exist) """

        toolbar = self.app.get_toolbar()

        # get number of tracks in queue before queuing a track
        initial_tracks_count = self.app.get_queue_count()

        # switch to albums tab and select the album
        self.app.get_albums_page().click_album(0)

        # get track item to swipe and queue
        track = self.app.get_songs_view().get_track(0)

        # add track to the queue
        track.click_add_to_queue_action()

        # wait for track to be queued
        self.app.get_queue_count().wait_for(initial_tracks_count + 1)

        end_tracks_count = self.app.get_queue_count()

        # Assert that the song added to the list is not playing
        self.assertThat(self.player.currentIndex,
                        Eventually(NotEquals(end_tracks_count)))
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        toolbar.switch_to_now_playing()  # Switch to the now playing page

        # Re get now playing page as it has changed
        now_playing_page = self.app.get_now_playing_page()

        # verify song's metadata matches the item added to the Now Playing view
        current_track = now_playing_page.get_track(self.player.currentIndex)

        self.assertThat(current_track.get_label_text("artistLabel"),
                        Equals(self.tracks[0]["artist"]))
        self.assertThat(current_track.get_label_text("titleLabel"),
                        Equals(self.tracks[0]["title"]))

        # click on close button to close the page and now playing page
        self.app.main_view.go_back()

        # click the play button (toolbar) to start playing
        toolbar.click_play_button()
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

        # click the play button (toolbar) to stop playing
        toolbar.click_play_button()
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

    def test_play_pause_now_playing(self):
        """ Test playing and pausing a track (Music Library must exist) """

        self.app.populate_queue()  # populate queue

        now_playing_page = self.app.get_now_playing_page()

        # check that the player is playing and then select pause
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))
        now_playing_page.click_play_button()

        # check that the player is paused and then select play
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))
        now_playing_page.click_play_button()

        # check that the player is playing
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

    def test_next_previous(self):
        """ Test going to next track (Music Library must exist) """

        self.app.populate_queue()  # populate queue

        now_playing_page = self.app.get_now_playing_page()

        # save original song data for later
        orig_title = self.player.currentMeta.title
        orig_artist = self.player.currentMeta.author

        # check original track
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))
        logger.debug("Original Song %s, %s" % (orig_title, orig_artist))

        # select pause and check the player has stopped
        now_playing_page.click_play_button()
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        now_playing_page.set_shuffle(False)  # ensure shuffe is off

        # goal is to go back and forth and ensure 2 different songs
        now_playing_page.click_forward_button()

        # bgplaylists does not auto play after next/previous
        now_playing_page.click_play_button()

        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

        # select pause and check the player has stopped
        now_playing_page.click_play_button()
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        # ensure different song
        self.assertThat(self.player.currentMeta.title,
                        Eventually(NotEquals(orig_title)))
        self.assertThat(self.player.currentMeta.author,
                        Eventually(NotEquals(orig_artist)))

        logger.debug("Next Song %s, %s" % (self.player.currentMeta.title,
                                           self.player.currentMeta.author))

        now_playing_page.seek_to(0)  # seek to 0 (start)

        # select previous and ensure the track is playing
        now_playing_page.click_previous_button()

        # bgplaylists does not auto play after next/previous
        now_playing_page.click_play_button()

        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

        # select pause and check the player has stopped
        now_playing_page.click_play_button()
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        # ensure we're back to original song
        self.assertThat(self.player.currentMeta.title,
                        Eventually(Equals(orig_title)))
        self.assertThat(self.player.currentMeta.author,
                        Eventually(Equals(orig_artist)))

    def test_mp3(self):
        """ Test that mp3 "plays" or at least doesn't crash on load """

        toolbar = self.app.get_toolbar()

        # Get list of tracks which are mp3 and then take the index of the first
        i = [i for i, track in enumerate(self.tracks)
             if track["source"].endswith("mp3")][0]

        initial_tracks_count = self.app.get_queue_count()

        # switch to tracks page
        tracks_page = self.app.get_songs_page()

        # get track row and swipe to reveal actions
        track = tracks_page.get_track(i)
        track.click_add_to_queue_action()  # add track to queue

        # wait for the player index to change
        self.player.currentIndex.wait_for(0)

        # ensure that the queue count has increased
        self.assertThat(self.app.get_queue_count(),
                        Eventually(Equals(initial_tracks_count + 1)))

        # Ensure the current track is mp3
        self.assertThat(self.player.currentItemSource.endswith("mp3"),
                        Equals(True))

        # Start playing the track (click from toolbar)
        toolbar.click_play_button()

        # Check that the track is playing
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

        # Stop playing the track (click from toolbar)
        toolbar.click_play_button()

        # Check current meta data is correct
        self.assertThat(self.player.currentMeta.title,
                        Eventually(Equals(self.tracks[i]["title"])))
        self.assertThat(self.player.currentMeta.author,
                        Eventually(Equals(self.tracks[i]["artist"])))

    def test_shuffle(self):
        """ Test shuffle (Music Library must exist) """

        self.app.populate_queue()  # populate queue

        # at this point the track is playing and shuffle is enabled

        now_playing_page = self.app.get_now_playing_page()

        now_playing_page.set_repeat(True)
        now_playing_page.set_shuffle(True)

        # pause the track if it is playing
        if self.player.isPlaying:
            now_playing_page.click_play_button()

        self.player.isPlaying.wait_for(False)

        count = 0
        previous_index = -1

        # Keep going until the index is not previous + 1 (with wrapping)
        # or previous == currentIndex (to ensure shuffle is working)
        while ((previous_index + 1) % self.player.count ==
               self.player.currentIndex or
               previous_index == self.player.currentIndex):
            logger.debug("count %s" % (count))

            # check count is valid
            self.assertThat(count, LessThan(100))

            # store this index as the previous
            previous_index = self.player.currentIndex

            # select next track
            now_playing_page.click_forward_button()

            # pause the track if it is playing
            if self.player.isPlaying:
                now_playing_page.click_play_button()

            self.player.isPlaying.wait_for(False)

            # toggle shuffle to increase random
            now_playing_page.set_shuffle(False)
            now_playing_page.set_shuffle(True)

            count += 1

    def test_show_albums_page(self):
        """tests navigating to the Albums tab and displaying the album page"""

        # switch to albums tab
        albums_page = self.app.get_albums_page()
        albums_page.click_album(0)  # select album

        # get songs page album artist
        songs_page = self.app.get_songs_view()
        artist_label = songs_page.get_header_artist_label()

        # build list of tracks sorted by album
        tracks = self.tracks[:]
        tracks.sort(key=lambda track: track["album"])

        # check that the first is the same as
        self.assertThat(artist_label.text,
                        Eventually(Equals(tracks[0]["artist"])))

        # click on close button to close songs page
        self.app.main_view.go_back()

        # check that the albums page is now visible
        self.assertThat(albums_page.visible, Eventually(Equals(True)))

    def test_add_song_to_queue_from_albums_page(self):
        """tests navigating to the Albums tab and adding a song to queue"""

        toolbar = self.app.get_toolbar()

        # get number of tracks in queue before queuing a track
        initial_tracks_count = self.app.get_queue_count()

        # switch to albums tab
        albums_page = self.app.get_albums_page()
        albums_page.click_album(0)  # select album

        # build list of tracks sorted by album
        tracks = self.tracks[:]
        tracks.sort(key=lambda track: track["album"])

        # get track item to swipe and queue
        songs_page = self.app.get_songs_view()

        track = songs_page.get_track(0)
        track.click_add_to_queue_action()  # add track to the queue

        # verify track queue has added one to initial value
        self.assertThat(self.app.get_queue_count(),
                        Eventually(Equals(initial_tracks_count + 1)))

        # Assert that the song added to the list is not playing
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        toolbar.switch_to_now_playing()  # Switch to the now playing page

        # Re get now playing page as it has changed
        now_playing_page = self.app.get_now_playing_page()

        # verify song's metadata matches the item added to the Now Playing view
        current_track = now_playing_page.get_track(self.player.currentIndex)

        self.assertThat(current_track.get_label_text("artistLabel"),
                        Equals(tracks[0]["artist"]))
        self.assertThat(current_track.get_label_text("titleLabel"),
                        Equals(tracks[0]["title"]))

        # click on close button to close nowplaying page
        self.app.main_view.go_back()

        # check that the songs page is now visible
        self.assertThat(songs_page.visible, Eventually(Equals(True)))

    def test_add_songs_to_queue_from_songs_tab_and_play(self):
        """tests navigating to the Songs tab and adding the library to the
           queue with the selected item being played. """

        # get number of tracks in queue before queuing a track
        initial_tracks_count = self.app.get_queue_count()

        self.app.populate_queue()  # populate queue

        # get now playing again as it has moved
        now_playing_page = self.app.get_now_playing_page()

        # verify track queue has added all songs to initial value
        self.assertThat(self.app.get_queue_count(),
                        Equals(initial_tracks_count + 3))

        # Assert that the song added to the list is playing
        self.assertThat(self.player.currentIndex,
                        Eventually(NotEquals(self.app.get_queue_count())))
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

        # verify song's metadata matches the item added to the Now Playing view
        current_track = now_playing_page.get_track(self.player.currentIndex)

        self.assertThat(current_track.get_label_text("artistLabel"),
                        Equals(self.tracks[0]["artist"]))
        self.assertThat(current_track.get_label_text("titleLabel"),
                        Equals(self.tracks[0]["title"]))

    def test_add_song_to_queue_from_songs_tab(self):
        """tests navigating to the Songs tab and adding a song from the library
           to the queue via the expandable list view item. """

        toolbar = self.app.get_toolbar()

        # get number of tracks in queue before queuing a track
        initial_tracks_count = self.app.get_queue_count()

        # switch to tracks page
        tracks_page = self.app.get_songs_page()

        # get track row and swipe to reveal actions
        track = tracks_page.get_track(0)
        track.click_add_to_queue_action()  # add track to queue

        # verify track queue has added all songs to initial value
        self.assertThat(self.app.get_queue_count(),
                        Eventually(Equals(initial_tracks_count + 1)))

        # Assert that the song added to the list is not playing
        self.assertThat(self.player.currentIndex,
                        Eventually(NotEquals(self.app.get_queue_count())))
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

        toolbar.switch_to_now_playing()  # Switch to the now playing page

        # Re get now playing page as it has changed
        now_playing_page = self.app.get_now_playing_page()

        # verify song's metadata matches the item added to the Now Playing view
        current_track = now_playing_page.get_track(self.player.currentIndex)

        self.assertThat(current_track.get_label_text("artistLabel"),
                        Equals(self.tracks[0]["artist"]))
        self.assertThat(current_track.get_label_text("titleLabel"),
                        Equals(self.tracks[0]["title"]))

    def test_create_playlist_from_songs_tab(self):
        """tests navigating to the Songs tab and creating a playlist by
           selecting a song to add it to a new playlist. """

        # switch to tracks page
        tracks_page = self.app.get_songs_page()

        # get track row and swipe to reveal actions
        track = tracks_page.get_track(0)
        track.click_add_to_playlist_action()  # add track to queue

        add_to_playlist_page = self.app.get_add_to_playlist_page()

        # get initial list view playlist count
        playlist_count = add_to_playlist_page.get_count()

        # click on New playlist button in header
        add_to_playlist_page.click_new_playlist_action()

        # get dialog
        new_dialog = self.app.get_new_playlist_dialog()

        # input playlist name
        new_dialog.type_new_playlist_dialog_name("myPlaylist")

        # click on the create Button
        new_dialog.click_new_playlist_dialog_create_button()

        # verify playlist has been sucessfully created
        self.assertThat(add_to_playlist_page.get_count(),
                        Eventually(Equals(playlist_count + 1)))

        self.assertThat(add_to_playlist_page.get_playlist(0).name,
                        Equals("myPlaylist"))

        # select playlist to add song to
        add_to_playlist_page.click_playlist(0)

        # open playlists page
        playlists_page = self.app.get_playlists_page()

        # verify song has been added to playlist
        self.assertThat(playlists_page.get_count(), Equals(1))

    def test_select_and_delete_playlist(self):
        """tests deleting a playlist by creating a playlist,
            selecting it, and then deleting it. """

        # switch to playlist page
        playlists_page = self.app.get_playlists_page()

        # get initial list view playlist count
        playlist_count = playlists_page.get_count()

        # click on New playlist button in header
        playlists_page.click_new_playlist_action()

        # get dialog
        new_dialog = self.app.get_new_playlist_dialog()

        # input playlist name
        new_dialog.type_new_playlist_dialog_name("testDeletePlaylist")

        # click on the create Button
        new_dialog.click_new_playlist_dialog_create_button()

        # verify playlist has been sucessfully created
        self.assertThat(playlists_page.get_count(),
                        Eventually(Equals(playlist_count + 1)))

        self.assertThat(playlists_page.get_playlist(0).primaryText,
                        Equals("testDeletePlaylist"))

        # select the playlist that was just created
        playlists_page.click_playlist(0)

        # click the delete icon
        playlists_songs_page = self.app.get_songs_view()
        playlists_songs_page.click_delete_playlist_action()

        # get dialog
        delete_dialog = self.app.get_delete_playlist_dialog()

        # click on the remove Button
        delete_dialog.click_remove_playlist_dialog_remove_button()

        playlists_page = self.app.get_playlists_page()

        # verify that the playlist has been removed
        self.assertThat(playlists_page.get_count(), Equals(playlist_count))

    def test_artists_tab_album(self):
        """tests navigating to the Artists tab and playing an album"""

        # get number of tracks in queue before queuing a track
        initial_tracks_count = self.app.get_queue_count()

        # switch to artists tab
        artists_page = self.app.get_artists_page()
        artists_page.click_artist(0)

        # build list of tracks sorted by artist
        tracks = self.tracks[:]
        tracks.sort(key=lambda track: track["artist"])

        # get albums (by an artist) page
        albums_page = self.app.get_artist_view_page()

        # check album artist label is correct
        self.assertThat(albums_page.get_artist(), Equals(tracks[0]["artist"]))

        # click on album to show tracks
        albums_page.click_artist(0)

        # get song page album artist
        songs_page = self.app.get_songs_view()

        # check the artist label
        artist_label = songs_page.get_header_artist_label()
        self.assertThat(artist_label.text, Equals(tracks[0]["artist"]))

        # click on track to play
        songs_page.click_track(0)

        # get now playing again as it has moved
        now_playing_page = self.app.get_now_playing_page()

        # verify track queue has added the song to the initial value
        self.assertThat(self.app.get_queue_count(),
                        Equals(initial_tracks_count + 1))

        # Assert that the song added to the list is playing
        self.assertThat(self.player.currentIndex,
                        Eventually(NotEquals(self.app.get_queue_count())))
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

        # verify song's metadata matches the item added to the Now Playing view
        current_track = now_playing_page.get_track(self.player.currentIndex)

        self.assertThat(current_track.get_label_text("artistLabel"),
                        Equals(tracks[0]["artist"]))
        self.assertThat(current_track.get_label_text("titleLabel"),
                        Equals(tracks[0]["title"]))

    def test_swipe_to_delete_song(self):
        """tests navigating to the Now Playing queue, swiping to delete a
        track, and confirming the delete action. """

        self.app.populate_queue()  # populate queue

        now_playing_page = self.app.get_now_playing_page()

        # get initial queue count
        initial_queue_count = self.app.get_queue_count()

        # get track row and swipe to reveal swipe to delete
        track = now_playing_page.get_track(0)
        track.click_remove_action()

        # verify song has been deleted
        self.assertThat(self.app.get_queue_count(),
                        Eventually(Equals(initial_queue_count - 1)))

    def test_playback_stops_when_last_song_ends_and_repeat_off(self):
        """Check that playback stops when the last song in the queue ends"""

        self.app.populate_queue()  # populate queue

        now_playing_page = self.app.get_now_playing_page()

        now_playing_page.set_shuffle(False)
        now_playing_page.set_repeat(False)

        # Skip through all songs in queue, stopping on last one.
        for count in range(0, self.app.get_queue_count() - 1):
            now_playing_page.click_forward_button()

        # When the last song ends, playback should stop
        self.assertThat(self.player.isPlaying, Eventually(Equals(False)))

    def test_playback_repeats_when_last_song_ends_and_repeat_on(self):
        """With repeat on, the 1st song should play after the last one ends"""

        self.app.populate_queue()  # populate queue

        now_playing_page = self.app.get_now_playing_page()

        now_playing_page.set_shuffle(False)
        now_playing_page.set_repeat(True)

        # Skip through all songs in queue, stopping on last one.
        for count in range(0, self.app.get_queue_count() - 1):
            now_playing_page.click_forward_button()

        # Make sure we loop back to first song after last song ends
        self.assertThat(self.player.currentMeta.title,
                        Eventually(Equals(self.tracks[0]["title"])))
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

    def test_pressing_next_from_last_song_plays_first_when_repeat_on(self):
        """With repeat on, skipping the last song jumps to the first track"""

        self.app.populate_queue()  # populate queue

        now_playing_page = self.app.get_now_playing_page()

        now_playing_page.set_shuffle(False)
        now_playing_page.set_repeat(True)

        # Skip through all songs in queue, INCLUDING last one.
        for count in range(0, self.app.get_queue_count() - 1):
            now_playing_page.click_forward_button()

        # Make sure we loop back to first song after last song ends
        self.assertThat(self.player.currentMeta.title,
                        Eventually(Equals(self.tracks[0]["title"])))
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

    def test_pressing_prev_from_first_song_plays_last_when_repeat_on(self):
        """With repeat on, 'previous' from the 1st song plays the last one."""

        self.app.populate_queue()  # populate queue

        now_playing_page = self.app.get_now_playing_page()

        now_playing_page.set_shuffle(False)
        now_playing_page.set_repeat(True)

        initial_song = self.player.currentMeta.title
        now_playing_page.click_previous_button()

        # If we're far enough into a song, pressing prev just takes us to the
        # beginning of that track.  In that case, hit prev again to actually
        # skip over the track.
        if self.player.currentMeta.title == initial_song:
            now_playing_page.click_previous_button()

        self.assertThat(self.player.currentMeta.title,
                        Eventually(Equals(self.tracks[-1]["title"])))
        self.assertThat(self.player.isPlaying, Eventually(Equals(True)))

    def test_pressing_prev_after_5_seconds(self):
        """Pressing previous after 5s jumps to the start of current song"""

        self.app.populate_queue()  # populate queue

        now_playing_page = self.app.get_now_playing_page()

        self.player.isPlaying.wait_for(True)  # ensure the track is playing

        # wait until > 5s
        self.player.position.wait_for(GreaterThan(5000))

        now_playing_page.click_play_button()  # pause the track
        self.player.isPlaying.wait_for(False)  # ensure the track has paused

        source = self.player.currentMeta.filename  # store current source

        now_playing_page.click_previous_button()  # click previous

        # resume the track (to ensure position updates)
        now_playing_page.click_play_button()

        # wait until < 5s
        self.player.position.wait_for(LessThan(5000))

        # Check that the source is the same
        self.assertThat(self.player.currentMeta.filename,
                        Eventually(Equals(source)))
