/*
 * Copyright (C) 2013, 2014, 2015
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

import QtQuick 2.4
import Ubuntu.Components 1.2
import "../"

ListItem {
    color: styleMusic.mainView.backgroundColor
    highlightColor: Qt.lighter(color, 1.2)

    // Store the currentColor so that actions can bind to it
    property var currentColor: highlighted ? highlightColor : color

    property alias column: musicRow.column
    property alias imageSource: musicRow.imageSource

    property bool multiselectable: false
    property bool reorderable: false

    signal itemClicked()

    onClicked: {
        if (selectMode) {
            selected = !selected;
        } else {
            itemClicked()
        }
    }

    onPressAndHold: {
        if (reorderable) {
            ListView.view.ViewItems.dragMode = !ListView.view.ViewItems.dragMode
        }

        if (multiselectable) {
            ListView.view.ViewItems.selectMode = !ListView.view.ViewItems.selectMode
        }
    }

    divider {
        visible: false
    }

    MusicRow {
        id: musicRow
        anchors {
            verticalCenter: parent.verticalCenter
        }
        height: parent.height
    }
}
