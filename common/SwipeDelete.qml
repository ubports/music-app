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

/* SwipeDelete object */
Rectangle {
    id: swipeBackground
    color: "transparent"
    height: parent.height
    state: "normal"
    width: parent.width * 3
    x: 0 - parent.width  // start out of view

    property string direction: ""
    property int duration: 0
    property bool deleteState: false
    property bool primed: false

    Rectangle {
        id: swipeBackgroundLeft
        anchors.left: parent.left
        color: styleMusic.common.black
        opacity: 0.7
        height: parent.height
        width: parent.width / 3
        Label {
            id: swipeBackgroundLeftText
            anchors.margins: units.gu(2)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: styleMusic.common.white
            fontSize: "large"
            horizontalAlignment: Text.AlignRight
            text: i18n.tr("Delete")
            verticalAlignment: Text.AlignVCenter
        }
        Icon {
            id: swipeBackgroundLeftImage
            anchors.margins: units.gu(2)
            anchors.right: swipeBackgroundLeftText.left
            anchors.verticalCenter: parent.verticalCenter
            name: "delete"
            height: parent.height
            width: height
        }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                deleteState = true;
            }
        }
    }

    Rectangle {
        id: swipeBackgroundRight
        anchors.right: parent.right
        color: styleMusic.common.black
        opacity: 0.7
        height: parent.height
        width: parent.width / 3
        Label {
            id: swipeBackgroundRightText
            anchors.left: parent.left
            anchors.margins: units.gu(2)
            anchors.verticalCenter: parent.verticalCenter
            color: styleMusic.common.white
            fontSize: "large"
            horizontalAlignment: Text.AlignLeft
            text: i18n.tr("Delete")
            verticalAlignment: Text.AlignVCenter
        }
        Icon {
            id: swipeBackgroundRightImage
            anchors.left: swipeBackgroundRightText.right
            anchors.margins: units.gu(2)
            anchors.verticalCenter: parent.verticalCenter
            name: "delete"
            height: parent.height
            width: height
        }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                deleteState = true;
            }
        }
    }
}
