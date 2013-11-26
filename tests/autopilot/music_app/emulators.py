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

        self.pointing_device.drag(x1, y1, x1, y1 - toolbar.height)

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
        return self.select_single("*", objectName="nowPlayingBackButtonObject")

    def get_albumstab(self):
        return self.select_single("Tab", objectName="albumstab")

    def get_albums_albumartist_list(self):
        return self.select_many("Label", objectName="albums-albumartist")

    def get_albums_albumartist(self, artistName):
        albumartistList = self.get_albums_albumartist_list()
        for item in albumartistList:
            if item.text == artistName:
                return item

    def get_album_sheet_artist(self):
        return self.select_single("Label", objectName="albumsheet-albumartist")

    def close_buttons(self):
        return self.select_many("Button", text="close")

    def get_album_sheet_close_button(self):
        closebuttons = self.close_buttons()
        for item in closebuttons:
            if item.enabled:
                return item
