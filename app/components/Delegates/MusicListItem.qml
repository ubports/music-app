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
import "../"


ListItemWithActions {
    id: root

    property alias column: musicRow.column
    property alias imageSource: musicRow.imageSource

    property bool reorderable: false
    property bool multiselectable: false

    signal reorder(int from, int to)

    onItemPressAndHold: {
        if (multiselectable) {
            selectionMode = true
        }
    }

    onSelectionModeChanged: {
        if (reorderable && selectionMode) {
            resetSwipe()
        }

        for (var j=0; j < _main.children.length; j++) {
            _main.children[j].anchors.rightMargin = reorderable && selectionMode ? actionReorderLoader.width + units.gu(2) : 0
        }

        parent.parent.state = selectionMode ? "multiselectable" : "normal"

        if (!selectionMode) {
            selected = false
        }
    }

    /* Highlight the listitem on press */
    Rectangle {
        id: listItemBrighten
        anchors {
            fill: parent
        }

        color: root.pressed ? styleMusic.common.white : "transparent"
        opacity: 0.1
    }

    /* Reorder Component */
    Loader {
        id: actionReorderLoader
        active: reorderable && selectionMode && root.parent.parent.selectedItems.length === 0
        anchors {
            bottom: parent.bottom
            right: parent.right
            rightMargin: units.gu(1)
            top: parent.top
        }
        asynchronous: true
        source: "../ListItemReorderComponent.qml"
    }

    MusicRow {
        id: musicRow
        anchors {
            verticalCenter: parent.verticalCenter
        }
        height: parent.height
    }
}
