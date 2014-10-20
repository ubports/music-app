/*
 * Copyright (C) 2013, 2014
 *      Andrew Hayzen <ahayzen@gmail.com>
 *      Nekhelesh Ramananthan <krnekhelesh@gmail.com>
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

UbuntuShape {
    id: coverRow

    // Property (array) to store the cover images
    property var covers

    // Property to set the size of the cover image
    property int size

    // Property to get the playlist count to determine the visibility of a cover image
    property int count

    // Property to set the spacing size, default to units.gu(1)
    property var spacing: units.gu(1)

    // Property to determine if item should appear pressed
    property bool pressed: false

    width: size
    height: size
    radius: "medium"
    image: finalImageRender

    // Component to assemble the pictures in a row with appropriate spacing.
    Row {
        id: imageRow

        width: coverRow.size
        height: width

        spacing: -coverRow.size + coverRow.spacing

        Repeater {
            id: repeat
            model: coverRow.count == 0 ? 1 : coverRow.count
            delegate: Image {
                width: coverRow.size
                height: width
                smooth: true
                source: coverRow.count !== 0 && coverRow.covers[index] !== "" && coverRow.covers[index] !== undefined
                        ? (coverRow.covers[index].art !== undefined
                           ? coverRow.covers[index].art
                           : "image://albumart/artist=" + coverRow.covers[index].author + "&album=" + coverRow.covers[index].album)
                        : Qt.resolvedUrl("../images/music-app-cover@30.png")
                sourceSize.height: height
                sourceSize.width: width
                onStatusChanged: {
                    if (status === Image.Error) {
                        source = Qt.resolvedUrl("../images/music-app-cover@30.png")
                    }
                }
            }
        }
    }

    // Component to render the cover images as one image which is then passed as argument to the Ubuntu Shape widget.
    ShaderEffectSource {
        id: finalImageRender
        sourceItem: imageRow
        width: units.gu(0.1)
        height: width
        anchors.centerIn: parent
        hideSource: true
    }

    // TODO: If http://pad.lv/1354753 is fixed to expose whether the Shape should appear pressed, update this as well.
    onPressedChanged: {
       pressed ? borderSource = "radius_pressed.sci"
               : borderSource = "radius_idle.sci"
    }
}

