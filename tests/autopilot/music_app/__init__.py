# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013, 2014 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""music-app tests and emulators - top level package."""
import ubuntuuitoolkit
from time import sleep


class MusicAppException(Exception):
    """Exception raised when there's an error in the Music App."""


class MusicApp(object):
    """Autopilot helper object for the Music application."""

    def __init__(self, app_proxy):
        self.app = app_proxy
        self.main_view = self.app.wait_select_single(MainView)
        self.player = self.app.select_single(Player, objectName='player')

    def get_now_playing_page(self):
        return self.app.wait_select_single(MusicNowPlaying,
                                           objectName="nowPlayingPage")

    def get_toolbar(self):
        return self.app.select_single(MusicToolbar,
                                      objectName="musicToolbarObject")

    def get_tracks_page(self):
        """Open the Tracks tab.

        :return: The autopilot custom proxy object for the TracksPage.

        """
        self.main_view.switch_to_tab('tracksTab')

        return self.main_view.select_single(
            Page11, objectName='tracksPage')

    @property
    def loaded(self):
        return (not self.main_view.select_single("ActivityIndicator",
                objectName="LoadingSpinner").running and
                self.main_view.select_single("*", "allSongsModel").populated)

    def populate_queue(self):
        tracksPage = self.get_tracks_page()  # switch to track tab

        # get and click to play first track
        track = tracksPage.get_track(0)
        self.app.pointing_device.click_object(track)

        # TODO: when using bottom edge wait for .isReady on tracksPage


class Page(ubuntuuitoolkit.UbuntuUIToolkitCustomProxyObjectBase):
    """Autopilot helper for Pages."""
    def __init__(self, *args):
        super(Page, self).__init__(*args)
        # XXX we need a better way to keep reference to the main view.
        # --elopio - 2014-01-31
        self.main_view = self.get_root_instance().select_single(MainView)


class MusicPage(Page):
    def __init__(self, *args):
        super(Page, self).__init__(*args)


# FIXME: Represents MusicTracks related to bug 1341671 and bug 1337004
class Page11(MusicPage):
    """ Autopilot helper for the tracks page """
    def __init__(self, *args):
        super(MusicPage, self).__init__(*args)

    def get_track(self, i):
        return (self.wait_select_single("ListItemWithActions",
                objectName="tracksTabListItem" + str(i)))


class Player(ubuntuuitoolkit.UbuntuUIToolkitCustomProxyObjectBase):
    """Autopilot helper for Player"""


class MusicNowPlaying(MusicPage):
    """ Autopilot helper for now playing page """
    def __init__(self, *args):
        super(MusicPage, self).__init__(*args)

        root = self.get_root_instance()

        self.player = root.select_single(Player, objectName="player")
        self.toolbar = root.select_single(MusicToolbar,
                                          objectName="musicToolbarObject")

    def get_count(self):
        return self.select_single("QQuickListView",
                                  objectName="nowPlayingQueueList").count

    def get_track(self, i):
        return (self.wait_select_single("ListItemWithActions",
                objectName="nowPlayingListItem" + str(i)))

    def set_repeat(self, state):
        repeat_button = self.toolbar.get_full_repeat_button()

        if self.player.repeat != state:
            self.pointing_device.click_object(repeat_button)

        self.player.repeat.wait_for(state)

    def set_shuffle(self, state):
        shuffle_button = self.toolbar.get_full_shuffle_button()

        # TODO: check button opacity = player state before?

        if self.player.shuffle != state:
            self.pointing_device.click_object(shuffle_button)

        self.player.shuffle.wait_for(state)


class MusicToolbar(ubuntuuitoolkit.UbuntuUIToolkitCustomProxyObjectBase):
    """Autopilot helper for the toolbar

    expanded - refers to things when the toolbar is in its smaller state
    full - refers to things when the toolbar is in its larger state
    """

    def get_expanded_play_button(self):
        return self.wait_select_single("*", objectName="expandedPlayShape")

    def get_full_forward_button(self):
        return self.wait_select_single("*", objectName="fullForwardShape")

    def get_full_play_button(self):
        return self.wait_select_single("*", objectName="fullPlayShape")

    def get_full_previous_button(self):
        return self.wait_select_single("*", objectName="fullPreviousShape")

    def get_full_repeat_button(self):
        return self.wait_select_single("*", objectName="fullRepeatShape")

    def get_full_shuffle_button(self):
        return self.wait_select_single("*", objectName="fullShuffleShape")

    def show(self):
        self.pointing_device.move_to_object(self)

        x1, y1 = self.pointing_device.position()

        y1 -= (self.height / 2) + 1  # get position at top of toolbar

        self.pointing_device.drag(x1, y1, x1, y1 - self.fullHeight)


class MainView(ubuntuuitoolkit.MainView):
    """Autopilot custom proxy object for the MainView."""
    retry_delay = 0.2

    def __init__(self, *args):
        super(MainView, self).__init__(*args)
        self.visible.wait_for(True)

        # wait for activity indicator to stop spinning
        spinner = self.wait_select_single("ActivityIndicator",
                                          objectName="LoadingSpinner")
        spinner.running.wait_for(False)

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

    def get_player_control_title(self):
        return self.select_single("Label", objectName="playercontroltitle")

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
        return self.wait_select_single("*",
                                       objectName="addToQueueAction",
                                       primed=True)

    def get_add_to_playlist_action(self):
        return self.wait_select_single("*",
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
        return self.wait_select_single(
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

    def get_swipedelete_icon(self):
        return self.wait_select_single(
            "*", objectName="swipeDeleteAction",
            primed=True)
