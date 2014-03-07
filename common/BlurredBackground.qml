/*
 * Copyright (C) 2013 Andrew Hayzen <ahayzen@gmail.com>
 *                    Daniel Holm <d.holmen@gmail.com>
 *                    Victor Thompson <victor.thompson@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Components 0.1
import QtGraphicalEffects 1.0

// Blurred background
Rectangle {
    anchors.fill: parent
    property string cover: player.currentMetaCover !== "" ?
                               player.currentMetaCover :
                               "images/cover_default.png"
    // the album art
    Image {
        id: backgroundImage
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        source: cover // this has to be fixed for the default cover art to work - cant find in this dir
        height: Math.max(parent.height, parent.width)
        width: Math.max(parent.height, parent.width)
        visible: false
    }
    // the blur
    FastBlur {
        id: backgroundBlur
        anchors.fill: backgroundImage
        source: backgroundImage
        radius: units.dp(42)
    }
    // transparent white layer
    Rectangle {
        anchors.fill: parent
        color: "white"
        opacity: 0.7
    }
    onCoverChanged: {
        // TODO: This is a work around for LP:1261078. Ideally, there should be
        //       a better way of getting the blur to repaint
        backgroundBlur.source = null
        backgroundBlur.source = backgroundImage
    }
}

