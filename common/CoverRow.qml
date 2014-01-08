/*
 * Copyright (C) 2013 Nekhelesh Ramananthan <krnekhelesh@gmail.com>
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

Row {
    id: coverRow

    // Property (array) to store the cover images
    property var covers

    // Property to set the size of the cover image
    property int size

    // Property to get the playlist count to determine the visibility of a cover image
    property int count

    Repeater {
        model: 4
        delegate: UbuntuShape {
            height: coverRow.size
            width: height
            visible: coverRow.count > index
            image: Image {
                source: coverRow.covers[index] !== "" ? coverRow.covers[index] : Qt.resolvedUrl("../images/cover_default_icon.png")
            }
        }
    }
}
