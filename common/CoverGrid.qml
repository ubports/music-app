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

Rectangle {
    id: coverGrid
    color: "transparent"
    height: size
    width: size

    // Property (array) to store the cover images
    property var covers

    // Property to set the size of the cover image
    property int size

    // Property to determine if item should appear pressed
    property bool pressed: false

    onCoversChanged: {
        if (covers !== undefined) {
            while (covers.length > 4) {  // remove any covers after 4
                covers.pop()
            }
        }
    }

    // Component to assemble the pictures in a row with appropriate spacing.
    Flow {
        id: imageRow

        width: coverGrid.size
        height: width

        Repeater {
            id: repeat
            model: coverGrid.covers.length === 0 ? 1 : coverGrid.covers.length
            delegate: Image {
                fillMode: Image.PreserveAspectCrop
                height: coverGrid.size / (coverGrid.covers.length > 1 ? 2 : 1)
                width: coverGrid.size / (coverGrid.covers.length > 2 && !(coverGrid.covers.length === 3 && index === 2) ? 2 : 1)
                source: coverGrid.covers.length !== 0 && coverGrid.covers[index] !== "" && coverGrid.covers[index] !== undefined
                        ? (coverGrid.covers[index].art !== undefined
                           ? coverGrid.covers[index].art
                           : "image://albumart/artist=" + coverGrid.covers[index].author + "&album=" + coverGrid.covers[index].album)
                        : Qt.resolvedUrl("../images/music-app-cover@30.png")
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
        anchors {
            fill: parent
        }
        height: width
        hideSource: true
        sourceItem: imageRow
    }
}

