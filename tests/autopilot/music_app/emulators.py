# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013, 2014 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Music app autopilot emulators."""
from ubuntuuitoolkit import emulators as toolkit_emulators
from time import sleep


class MainView(toolkit_emulators.MainView):

    """An emulator class that makes it easy to interact with the
    music-app.
    """
    retry_delay = 0.2

    def get_toolbar(self):
        return self.select_single("MusicToolbar",
                                  objectName="musicToolbarObject")

    def select_many_retry(self, object_type, **kwargs):
        """Returns the item that is searched for with app.select_many
        In case of no item was not found (not created yet) a second attempt is
        taken 1 second later"""
        items = self.select_many(object_type, **kwargs)
        tries = 10
        while len(items) < 1 and tries > 0:
            sleep(self.retry_delay)
            items = self.select_many(object_type, **kwargs)
            tries = tries - 1
        return items

    def tap_item(self, item):
        self.pointing_device.move_to_object(item)
        self.pointing_device.press()
        sleep(2)
        self.pointing_device.release()

    def seek_to_0(self):
        # Get the progress bar object
        progressBar = self.wait_select_single(
            "*", objectName="progressBarShape")

        # Move to the progress bar and get the position
        self.pointing_device.move_to_object(progressBar)
        x1, y1 = self.pointing_device.position()

        self.pointing_device.drag(x1, y1, x1 - (progressBar.width / 2) + 1, y1)

    def show_toolbar(self):
        # Get the toolbar object and create a mouse
        toolbar = self.get_toolbar()

        # Move to the toolbar and get the position
        self.pointing_device.move_to_object(toolbar)
        x1, y1 = self.pointing_device.position()

        y1 -= (toolbar.height / 2) + 1  # get position at top of toolbar

        self.pointing_device.drag(x1, y1, x1, y1 - toolbar.fullHeight)

    def add_to_queue_from_albums_tab_album_page(self, artistName, trackTitle):
        # switch to albums tab
        self.switch_to_tab("albumstab")

        # select album
        albumartist = self.get_albums_albumartist(artistName)
        self.pointing_device.click_object(albumartist)

        # get track item to swipe and queue
        trackitem = self.get_songs_page_listview_tracktitle(trackTitle)
        songspage = self.get_songs_page_listview()

        # get coordinates to swipe
        start_x = int(songspage.globalRect.x +
                      (songspage.globalRect.width * 0.9))
        stop_x = int(songspage.globalRect.x)
        line_y = int(trackitem.globalRect.y)

        # swipe to add to queue
        self.pointing_device.move(start_x, line_y)
        self.pointing_device.drag(start_x, line_y, stop_x, line_y)

        # click on add to queue
        queueaction = self.get_add_to_queue_action()
        self.pointing_device.click_object(queueaction)

    def tap_new_playlist_action(self):
        header = self.get_header()
        header.click_action_button('newplaylistButton')

    def get_player(self):
        return self.select_single("*", objectName="player")

    def get_play_button(self):
        return self.wait_select_single("*", objectName="playshape")

    def get_now_playing_play_button(self):
        return self.wait_select_single("*", objectName="nowPlayingPlayShape")

    def get_repeat_button(self):
        return self.wait_select_single("*", objectName="repeatShape")

    def get_shuffle_button(self):
        return self.wait_select_single("*", objectName="shuffleShape")

    def get_forward_button(self):
        return self.wait_select_single("*", objectName="forwardshape")

    def get_previous_button(self):
        return self.wait_select_single("*", objectName="previousshape")

    def get_player_control_title(self):
        return self.select_single("Label", objectName="playercontroltitle")

    def get_spinner(self):
        return self.select_single("ActivityIndicator",
                                  objectName="LoadingSpinner")

    def get_first_genre_item(self):
        return self.wait_select_single("*", objectName="genreItemObject")

    def get_albumstab(self):
        return self.select_single("Tab", objectName="albumstab")

    def get_albums_albumartist_list(self):
        return self.select_many("Label", objectName="albums-albumartist")

    def get_albums_albumartist(self, artistName):
        albumartistList = self.get_albums_albumartist_list()
        for item in albumartistList:
            if item.text == artistName:
                return item

    def get_add_to_queue_action(self):
        return self.wait_select_single("Action",
                                       objectName="addToQueueAction",
                                       primed=True)

    def get_add_to_playlist_action(self):
        return self.wait_select_single("Action",
                                       objectName="addToPlaylistAction",
                                       primed=True)

    def get_add_to_queue_button(self):
        return self.wait_select_single("QQuickImage",
                                       objectName="albumpage-queue-all")

    def get_album_page_artist(self):
        return self.wait_select_single("Label",
                                       objectName="albumpage-albumartist")

    def get_songs_page_artist(self):
        return self.wait_select_single("Label",
                                       objectName="songspage-albumartist")

    def get_artist_page_artist(self):
        return self.wait_select_single("Label",
                                       objectName="artistpage-albumartist")

    def get_artist_page_artist_cover(self):
        return self.wait_select_single("*",
                                       objectName="artistpage-albumcover")

    def get_artiststab(self):
        return self.select_single("Tab", objectName="artiststab")

    def get_artists_artist_list(self):
        return self.select_many("Label", objectName="artists-artist")

    def get_artists_artist(self, artistName):
        artistList = self.get_artists_artist_list()
        for item in artistList:
            if item.text == artistName:
                return item

    def close_buttons(self):
        return self.select_many("Button", text="close")

    def get_album_page_listview_tracktitle(self, trackTitle):
        tracktitles = self.select_many_retry(
            "Label", objectName="albumpage-tracktitle")
        for item in tracktitles:
            if item.text == trackTitle:
                return item

    def get_songs_page_listview_tracktitle(self, trackTitle):
        tracktitles = self.select_many_retry(
            "Label", objectName="songspage-tracktitle")
        for item in tracktitles:
            if item.text == trackTitle:
                return item

    def get_queue_track_count(self):
        queuelist = self.select_single(
            "QQuickListView", objectName="queuelist")
        return queuelist.count

    def get_queue_now_playing_artist(self, artistName):
        playingartists = self.select_many(
            "Label", objectName="nowplayingartist")
        for item in playingartists:
            if item.text == artistName:
                return item

    def get_queue_now_playing_title(self, trackTitle):
        playingtitles = self.select_many(
            "Label", objectName="nowplayingtitle")
        for item in playingtitles:
            if item.text == trackTitle:
                return item

    def get_tracks_tab_listview(self):
        return self.select_single("QQuickListView",
                                  objectName="trackstab-listview")

    def get_songs_page_listview(self):
        return self.select_single("QQuickListView",
                                  objectName="songspage-listview")

    def get_songs_tab_tracktitle(self, trackTitle):
        tracktitles = self.select_many_retry(
            "Label", objectName="tracktitle")
        for item in tracktitles:
            if item.text == trackTitle:
                return item

    def get_newPlaylistDialog_createButton(self):
        return self.wait_select_single(
            "Button", objectName="newPlaylistDialog_createButton")

    def get_newPlaylistDialog_name_textfield(self):
        return self.wait_select_single(
            "TextField", objectName="playlistnameTextfield")

    def get_addtoplaylistview(self):
        return self.select_many_retry(
            "QQuickListView", objectName="addtoplaylistview")

    def get_playlistname(self, playlistname):
        playlistnames = self.select_many_retry(
            "Standard", objectName="playlist")
        for item in playlistnames:
            if item.name == playlistname:
                return item

    def get_playlistslist(self):
        return self.wait_select_single(
            "QQuickListView", objectName="playlistslist")

    def get_MusicNowPlaying_page(self):
        return self.wait_select_single(
            "MusicNowPlaying", objectName="nowplayingpage")

    def get_swipedelete_icon(self):
        return self.wait_select_single(
            "Action", objectName="swipeDeleteAction",
            primed=True)
