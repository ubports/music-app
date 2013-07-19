# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Music app autopilot emulators."""


class MainWindow(object):
    """An emulator class that makes it easy to interact with the
    music-app.

    """
    def __init__(self, app):
        self.app = app

    def get_qml_view(self):
        """Get the main QML view"""
        return self.app.select_single("QQuickView")

    def get_object(self, typeName, name):
        """Get a specific object"""
        return self.app.select_single(typeName, objectName=name)

    def get_objects(self, typeName, name):
        """Get more than one object"""
        return self.app.select_many(typeName, objectName=name)

