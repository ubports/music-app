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

    def select_single_retry(self, object_type, **kwargs):
        """Returns the item that is searched for with app.select_single
        In case of the item was not found (not created yet) a second attempt is
        taken 1 second later."""
        item = self.select_single(object_type, **kwargs)
        tries = 10
        while item is None and tries > 0:
            sleep(self.retry_delay)
            item = self.select_single(object_type, **kwargs)
            tries = tries - 1
        return item

    def tap_item(self, item):
        self.pointing_device.move_to_object(item)
        self.pointing_device.press()
        sleep(2)
        self.pointing_device.release()

    def show_toolbar(self):
        #Ripped from emulator, this needs to be removed
        #and replaced with the open_toolbar routine
        x, y, _, _ = self.globalRect
        line_x = x + self.width * 0.50
        start_y = y + self.height - 1
        stop_y = y + self.height - self.get_toolbar().height

        self.pointing_device.drag(line_x, start_y, line_x, stop_y)

    def get_play_button(self):
        return self.select_single("*", objectName="playshape")

    def get_now_playing_play_button(self):
        return self.select_single("*", objectName="nowPlayingPlayShape")

    def get_repeat_button(self):
        return self.select_single("UbuntuShape", objectName="repeatShape")

    def get_forward_button(self):
        return self.select_single("UbuntuShape", objectName="forwardshape")

    def get_previous_button(self):
        return self.select_single("UbuntuShape", objectName="previousshape")

    def get_player_control_title(self):
        return self.select_single("Label", objectName="playercontroltitle")

    def get_spinner(self):
        return self.select_single("ActivityIndicator",
                                  objectName="LoadingSpinner")
