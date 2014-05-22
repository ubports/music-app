# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
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

    def show_toolbar(self):
        # Get the toolbar object and create a mouse
        toolbar = self.get_toolbar()

        # Move to the toolbar and get the position
        self.pointing_device.move_to_object(toolbar)
        x1, y1 = self.pointing_device.position()

        y1 -= (toolbar.height / 2) + 1  # get position at top of toolbar

        self.pointing_device.drag(x1, y1, x1, y1 - toolbar.fullHeight)

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

    def get_back_button(self):
        backButton = self.select_single("AbstractButton",
                                        objectName="backButton")
        return backButton

    def get_albumstab(self):
        return self.select_single("Tab", objectName="albumstab")

    def get_albums_albumartist_list(self):
        return self.select_many("Label", objectName="albums-albumartist")

    def get_albums_albumartist(self, artistName):
        albumartistList = self.get_albums_albumartist_list()
        for item in albumartistList:
            if item.text == artistName:
                return item

    def get_add_to_queue_button(self):
        return self.wait_select_single("QQuickImage",
                                       objectName="albumsheet-queue-all")

    def get_album_sheet_artist(self):
        return self.wait_select_single("Label",
                                       objectName="albumsheet-albumartist")

    def get_artist_sheet_artist(self):
        return self.wait_select_single("Label",
                                       objectName="artistsheet-albumartist")

    def get_artist_sheet_artist_cover(self):
        return self.wait_select_single("*",
                                       objectName="artistsheet-albumcover")

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

    def get_album_sheet_close_button(self):
        closebuttons = self.close_buttons()
        for item in closebuttons:
            if item.enabled:
                return item

    def get_album_sheet_listview_tracktitle(self, trackTitle):
        tracktitles = self.select_many_retry(
            "Label", objectName="albumsheet-tracktitle")
        for item in tracktitles:
            if item.text == trackTitle:
                return item

    def get_album_sheet_listview_trackicon(self, trackTitle):
        tracktitle = self.get_album_sheet_listview_tracktitle(trackTitle)
        tracktitle_position = tracktitle.globalRect[1]
        trackicons = self.select_many(
            "QQuickImage", objectName="expanditem")
        for item in trackicons:
            if item.globalRect[1] == tracktitle_position:
                return item

    def get_album_sheet_queuetrack_label(self):
        queuetracks = self.select_many_retry(
            "Label", objectName="queuetrack")
        for item in queuetracks:
            if item.visible:
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

    def get_songs_tab_tracktitle(self, trackTitle):
        tracktitles = self.select_many_retry(
            "Label", objectName="tracktitle")
        for item in tracktitles:
            if item.text == trackTitle:
                return item

    def get_songs_tab_trackimage(self, trackTitle):
        trackimages = self.select_many_retry(
            "QQuickImage", objectName="expanditem")
        tracktitles = self.get_songs_tab_tracktitle(trackTitle)
        imageheight = trackimages[0].height
        trackimage_position = tracktitles.globalRect[1] + (imageheight / 2)
        for item in trackimages:
            if item.globalRect[1] == trackimage_position:
                return item

    def get_songs_tab_add_to_queue_label(self):
        addtoqueue = self.select_many(
            "Label", objectName="queuetrack")
        for item in addtoqueue:
            if item.visible:
                return item

    def get_songs_tab_add_to_playlist_label(self):
        addtoplaylist = self.select_many(
            "Label", objectName="addtoplaylist")
        for item in addtoplaylist:
            if item.visible:
                return item

    def get_newplaylistButton(self):
        return self.select_many_retry("Button", objectName="newplaylistButton")

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
        swipedelete = self.wait_select_single(
            "SwipeDelete", direction="swipingRight")
        return swipedelete.select_many("Icon",  name="delete")[1]
