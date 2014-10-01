/*
 * Copyright (C) 2014
 *      Andrew Hayzen <ahayzen@gmail.com>
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
    id: card
    color: "transparent"
    height: cardColumn.childrenRect.height
    width: parent.parent.parent.cellWidth

    property alias imageSource: image.source
    property int margin: units.gu(2)
    property alias primaryText: primaryLabel.text
    property alias secondaryText: secondaryLabel.text

    signal clicked(var mouse)
    signal pressAndHold(var mouse)

    /* Animations */
    Behavior on height {
        UbuntuNumberAnimation {

        }
    }

    Behavior on width {
        UbuntuNumberAnimation {

        }
    }

    Behavior on x {
        UbuntuNumberAnimation {

        }
    }

    Behavior on y {
        UbuntuNumberAnimation {

        }
    }

    /* Background for card */
    Rectangle {
        id: bg
        anchors {
            fill: parent
        }
        color: "#2c2c34"
    }

    /* Column containing image and labels */
    Column {
        id: cardColumn
        anchors {
            fill: parent
        }
        spacing: units.gu(0.5)

        Image {
            id: image
            height: parent.width
            width: parent.width

            onStatusChanged: {
                if (status === Image.Error) {
                    source = Qt.resolvedUrl("../images/music-app-cover@30.png")
                }
            }
        }

        Rectangle {
            color: "transparent"
            height: units.gu(1)
            width: units.gu(1)
        }

        Label {
            id: primaryLabel
            anchors {
                left: parent.left
                leftMargin: units.gu(1)
                right: parent.right
                rightMargin: units.gu(1)
            }
            color: "#FFF"
            elide: Text.ElideRight
            fontSize: "small"
            opacity: 1.0
            wrapMode: Text.WordWrap
        }

        Label {
            id: secondaryLabel
            anchors {
                left: parent.left
                leftMargin: units.gu(1)
                right: parent.right
                rightMargin: units.gu(1)
            }
            color: "#FFF"
            elide: Text.ElideRight
            fontSize: "small"
            opacity: 0.4
            wrapMode: Text.WordWrap
        }

        Rectangle {
            color: "transparent"
            height: units.gu(1.5)
            width: units.gu(1)
        }
    }

    /* Overlay for when card is pressed */
    Rectangle {
        id: overlay
        anchors {
            fill: bg
        }
        color: "#000"
        opacity: 0

        Behavior on opacity {
            UbuntuNumberAnimation {

            }
        }
    }

    /* Capture mouse events */
    MouseArea {
        anchors {
            fill: parent
        }
        onClicked: card.clicked(mouse)
        onPressAndHold: card.pressAndHold(mouse)
        onPressedChanged: overlay.opacity = pressed ? 0.3 : 0
    }
}
