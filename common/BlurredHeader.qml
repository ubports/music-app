/*
 * Copyright (C) 2014
 *      Andrew Hayzen <ahayzen@gmail.com>
 *      Victor Thompson <victor.thompson@gmail.com>
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

import QtQuick 2.3
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0 as ListItem

ListItem.Standard {
    width: parent.width

    property alias bottomColumn: bottomColumnLoader.sourceComponent
    property alias coverSources: coversImage.covers
    property alias rightColumn: rightColumnLoader.sourceComponent

    BlurredBackground {
        id: blurredBackground
        height: parent.height
        art: coversImage.firstSource
    }

    CoverGrid {
        id: coversImage
        anchors {
            bottomMargin: units.gu(2)
            left: parent.left
            leftMargin: units.gu(2)
            rightMargin: units.gu(2)
            top: parent.top
            topMargin: units.gu(3)
        }
        size: parent.width > units.gu(60) ? units.gu(25.5) : (parent.width - units.gu(9)) / 2
    }

    Loader {
        id: rightColumnLoader
        anchors {
            bottom: coversImage.bottom
            left: coversImage.right
            leftMargin: units.gu(2)
        }
    }

    Loader {
        id: bottomColumnLoader
        anchors {
            left: coversImage.left
            right: parent.right
            rightMargin: units.gu(2)
            top: coversImage.bottom
            topMargin: units.gu(1)
        }
    }
}
