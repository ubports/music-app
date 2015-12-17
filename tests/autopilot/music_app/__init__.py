# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013, 2014, 2015 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""music-app tests and emulators - top level package."""
from ubuntuuitoolkit import (
    MainView, UbuntuUIToolkitCustomProxyObjectBase, UCListItem
)


class MusicAppException(Exception):
    """Exception raised when there's an error in the Music App."""


def click_object(func):
    """Wrapper which clicks the returned object"""
    def func_wrapper(self, *args, **kwargs):
        return self.pointing_device.click_object(func(self, *args, **kwargs))

    return func_wrapper


def ensure_now_playing_full(func):
    """Wrapper which ensures the now playing is full before clicking"""
    def func_wrapper(self, *args, **kwargs):
        if self.isListView:
            self.click_full_view()

        return func(self, *args, **kwargs)

    return func_wrapper


def ensure_now_playing_list(func):
    """Wrapper which ensures the now playing is list before clicking"""
    def func_wrapper(self, *args, **kwargs):
        if not self.isListView:
            self.click_queue_view()

        return func(self, *args, **kwargs)

    return func_wrapper


class MusicApp(object):
    """Autopilot helper object for the Music application."""

    def __init__(self, app_proxy):
        self.app = app_proxy

        # Use only objectName due to bug 1350532 as it is MainView12
        self.main_view = self.app.wait_select_single(
            objectName="musicMainView")

    def get_add_to_playlist_page(self):
        return self.app.wait_select_single(AddToPlaylist,
                                           objectName="addToPlaylistPage")

    def get_albums_page(self):
        self.main_view.switch_to_tab('albumsTab')

        return self.main_view.wait_select_single(
            Albums, objectName='albumsPage')

    def get_artist_view_page(self):
        return self.main_view.wait_select_single(
            ArtistView, objectName='artistViewPage')

    def get_artists_page(self):
        self.main_view.switch_to_tab('artistsTab')

        return self.main_view.wait_select_single(
            Artists, objectName='artistsPage')

    def get_new_playlist_dialog(self):
        return self.main_view.wait_select_single(
            Dialog, objectName="dialogNewPlaylist")

    def get_delete_playlist_dialog(self):
        return self.main_view.wait_select_single(
            RemovePlaylistDialog, objectName="dialogRemovePlaylist")

    def get_now_playing_page(self):
        return self.app.wait_select_single(NowPlaying,
                                           objectName="nowPlayingPage")

    def get_playlists_page(self):
        self.main_view.switch_to_tab('playlistsTab')

        return self.main_view.wait_select_single(
            Playlists, objectName='playlistsPage')

    def get_queue_count(self):
        return self.player.count

    def get_songs_view(self):
        return self.app.wait_select_single(SongsView, objectName="songsPage")

    def get_toolbar(self):
        return self.app.wait_select_single(MusicToolbar,
                                           objectName="musicToolbarObject")

    def get_songs_page(self):
        self.main_view.switch_to_tab('songsTab')

        return self.main_view.wait_select_single(
            Songs, objectName='songsPage')

    def get_walkthrough_page(self):
        return self.main_view.wait_select_single(Walkthrough,
                                                 objectName="walkthroughPage")

    @property
    def loaded(self):
        return (not self.main_view.select_single("ActivityIndicator",
                objectName="LoadingSpinner").running and
                self.main_view.select_single("*", "allSongsModel").populated)

    @property
    def player(self):
        # Get new player each time as data changes (eg currentMeta)
        return self.app.select_single(NewPlayer, objectName='player')

    def populate_queue(self):
        tracksPage = self.get_songs_page()  # switch to track tab

        # get and click to play first track
        track = tracksPage.get_track(0)
        self.app.pointing_device.click_object(track)

        tracksPage.visible.wait_for(False)  # wait until page has hidden

        # TODO: when using bottom edge wait for .isReady on tracksPage

        # wait for now playing page to be visible
        self.get_now_playing_page().visible.wait_for(True)


class Page(UbuntuUIToolkitCustomProxyObjectBase):
    """Autopilot helper for Pages."""
    def __init__(self, *args):
        super(Page, self).__init__(*args)
        # XXX we need a better way to keep reference to the main view.
        # --elopio - 2014-01-31

        # Use only objectName due to bug 1350532 as it is MainView12
        self.main_view = self.get_root_instance().select_single(
            objectName="musicMainView")


class MusicPage(Page):
    def __init__(self, *args):
        super(MusicPage, self).__init__(*args)


class Walkthrough(Page):
    """ Autopilot helper for the walkthrough page """
    def __init__(self, *args):
        super(Walkthrough, self).__init__(*args)

        self.visible.wait_for(True)

    @click_object
    def skip(self):
        return self.wait_select_single("UCLabel", objectName="skipLabel")


class Albums(MusicPage):
    """ Autopilot helper for the albums page """
    def __init__(self, *args):
        super(Albums, self).__init__(*args)

        self.visible.wait_for(True)

    @click_object
    def click_album(self, i):
        return (self.wait_select_single("*",
                objectName="albumsPageGridItem" + str(i)))


class Artists(MusicPage):
    """ Autopilot helper for the artists page """
    def __init__(self, *args):
        super(Artists, self).__init__(*args)

        self.visible.wait_for(True)

    @click_object
    def click_artist(self, i):
        return (self.wait_select_single("Card",
                objectName="artistsPageGridItem" + str(i)))


class Songs(MusicPage):
    """ Autopilot helper for the tracks page """
    def __init__(self, *args):
        super(Songs, self).__init__(*args)

        self.visible.wait_for(True)

    def get_track(self, i):
        return (self.wait_select_single(MusicListItem,
                objectName="tracksPageListItem" + str(i)))


class Playlists(MusicPage):
    """ Autopilot helper for the playlists page """
    def __init__(self, *args):
        super(Playlists, self).__init__(*args)

        self.visible.wait_for(True)

    def get_count(self):
        return self.wait_select_single(
            "CardView", objectName="playlistsCardView").count

    def click_new_playlist_action(self):
            self.main_view.get_header(
                ).click_action_button("newPlaylistButton")

    @click_object
    def click_playlist(self, i):
        return self.get_playlist(i)

    def get_playlist(self, i):
        return (self.wait_select_single("Card",
                objectName="playlistCardItem" + str(i)))


class AddToPlaylist(MusicPage):
    """ Autopilot helper for add to playlist page """
    def __init__(self, *args):
        super(AddToPlaylist, self).__init__(*args)

        self.visible.wait_for(True)

    def click_new_playlist_action(self):
        self.main_view.get_header().click_action_button("newPlaylistButton")

    @click_object
    def click_playlist(self, i):
        return self.get_playlist(i)

    def get_count(self):  # careful not to conflict until Page11 is fixed
        return self.wait_select_single(
            "CardView", objectName="addToPlaylistCardView").count

    def get_playlist(self, i):
        return (self.wait_select_single("Card",
                objectName="addToPlaylistCardItem" + str(i)))


class NewPlayer(UbuntuUIToolkitCustomProxyObjectBase):
    """Autopilot helper for NewPlayer"""


class NowPlaying(MusicPage):
    """ Autopilot helper for now playing page """
    def __init__(self, *args):
        super(NowPlaying, self).__init__(*args)

        self.visible.wait_for(True)

    @ensure_now_playing_full
    @click_object
    def click_forward_button(self):
        return self.wait_select_single("*", objectName="forwardShape")

    @ensure_now_playing_full
    @click_object
    def click_play_button(self):
        return self.wait_select_single("*", objectName="playShape")

    @ensure_now_playing_full
    @click_object
    def click_previous_button(self):
        return self.wait_select_single("*", objectName="previousShape")

    @ensure_now_playing_full
    @click_object
    def click_repeat_button(self):
        return self.wait_select_single("*", objectName="repeatShape")

    @ensure_now_playing_full
    @click_object
    def click_shuffle_button(self):
        return self.wait_select_single("*", objectName="shuffleShape")

    def click_full_view(self):
        self.main_view.get_header().switch_to_section_by_index(0)

    def click_queue_view(self):
        self.main_view.get_header().switch_to_section_by_index(1)

    @ensure_now_playing_list
    def get_track(self, i):
        return (self.wait_select_single(MusicListItem,
                objectName="nowPlayingListItem" + str(i)))

    @property
    def player(self):
        # Get new player each time as data changes (eg currentMeta)
        root = self.get_root_instance()
        return root.select_single(NewPlayer, objectName="player")

    @ensure_now_playing_full
    def seek_to(self, percentage):
        progress_bar = self.wait_select_single(
            "*", objectName="progressSliderShape")

        x1, y1, width, height = progress_bar.globalRect
        y1 += height // 2

        x2 = x1 + int(width * percentage / 100)

        self.pointing_device.drag(x1, y1, x2, y1)

    def set_repeat(self, state):
        if self.player.repeat != state:
            self.click_repeat_button()

        self.player.repeat.wait_for(state)

    def set_shuffle(self, state):
        if self.player.shuffle != state:
            self.click_shuffle_button()

        self.player.shuffle.wait_for(state)


class ArtistView(MusicPage):
    """ Autopilot helper for the albums page """
    def __init__(self, *args):
        super(ArtistView, self).__init__(*args)

        self.visible.wait_for(True)

    @click_object
    def click_artist(self, i):
        return self.wait_select_single("Card",
                                       objectName="albumsPageGridItem"
                                       + str(i))

    def get_artist(self):
        return self.wait_select_single("UCLabel",
                                       objectName="artistLabel").text


class SongsView(MusicPage):
    """ Autopilot helper for the songs page """
    def __init__(self, *args):
        super(SongsView, self).__init__(*args)

        self.visible.wait_for(True)

    def click_delete_playlist_action(self):
        self.main_view.get_header().click_action_button("deletePlaylist")

    @click_object
    def click_track(self, i):
        return self.get_track(i)

    def get_header_artist_label(self):
        return self.wait_select_single("UCLabel",
                                       objectName="songsPageHeaderAlbumArtist")

    def get_track(self, i):
        return (self.wait_select_single(MusicListItem,
                objectName="songsPageListItem" + str(i)))


class MusicToolbar(UbuntuUIToolkitCustomProxyObjectBase):
    """Autopilot helper for the toolbar"""
    def __init__(self, *args):
        super(MusicToolbar, self).__init__(*args)

    @click_object
    def click_play_button(self):
        return self.wait_select_single("*", objectName="playShape")

    @click_object
    def click_jump_to_now_playing(self):
        return self.wait_select_single("*", objectName="jumpNowPlaying")

    def switch_to_now_playing(self):
        self.click_jump_to_now_playing()

        root = self.get_root_instance()
        now_playing_page = root.wait_select_single(NowPlaying,
                                                   objectName="nowPlayingPage")

        now_playing_page.visible.wait_for(True)


class MusicListItem(UCListItem):
    def click_add_to_playlist_action(self):
        return self.trigger_trailing_action("addToPlaylistAction")

    def click_add_to_queue_action(self):
        return self.trigger_trailing_action("addToQueueAction")

    def click_remove_action(self):
        return self.trigger_leading_action("swipeDeleteAction",
                                           self.wait_until_destroyed)

    def get_label_text(self, name):
        return self.wait_select_single(objectName=name).text


class Dialog(UbuntuUIToolkitCustomProxyObjectBase):
    @click_object
    def click_new_playlist_dialog_create_button(self):
        return self.wait_select_single(
            "Button", objectName="newPlaylistDialogCreateButton")

    def type_new_playlist_dialog_name(self, text):
        self.wait_select_single(
            "TextField", objectName="playlistNameTextField").write(text)


class RemovePlaylistDialog(UbuntuUIToolkitCustomProxyObjectBase):
    @click_object
    def click_remove_playlist_dialog_remove_button(self):
        return self.wait_select_single(
            "Button", objectName="removePlaylistDialogRemoveButton")


class MainView(MainView):
    """Autopilot custom proxy object for the MainView."""
    retry_delay = 0.2

    def __init__(self, *args):
        super(MainView, self).__init__(*args)
        self.visible.wait_for(True)

        # wait for activity indicator to stop spinning
        spinner = self.wait_select_single("ActivityIndicator",
                                          objectName="LoadingSpinner")
        spinner.running.wait_for(False)
