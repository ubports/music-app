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

    property int listItemIndex: index
    property bool multiselectable: false
    property int previousListItemIndex: -1
    property bool reorderable: false

    signal reorder(int from, int to)

    onItemPressAndHold: {
        if (multiselectable) {
            selectionMode = true
        }
    }

    onListItemIndexChanged: {
        var i = parent.parent.selectedItems.lastIndexOf(previousListItemIndex)

        if (i !== -1) {
            parent.parent.selectedItems[i] = listItemIndex
        }

        previousListItemIndex = listItemIndex
    }

    onSelectedChanged: {
        if (selectionMode) {
            var tmp = parent.parent.selectedItems

            if (selected) {
                if (parent.parent.selectedItems.indexOf(listItemIndex) === -1) {
                    tmp.push(listItemIndex)
                    parent.parent.selectedItems = tmp
                }
            } else {
                tmp.splice(parent.parent.selectedItems.indexOf(listItemIndex), 1)
                parent.parent.selectedItems = tmp
            }
        }
    }

    onSelectionModeChanged: {
        if (reorderable && selectionMode) {
            resetSwipe()
        }

        for (var j=0; j < _main.children.length; j++) {
            if (_main.children[j] !== actionReorderLoader) {
                _main.children[j].anchors.rightMargin = reorderable && selectionMode ? actionReorderLoader.width + units.gu(2) : 0
            }
        }

        parent.parent.state = selectionMode ? "multiselectable" : "normal"

        if (!selectionMode) {
            selected = false
        }
    }

    /* Highlight the listitem on press */
    Rectangle {
        id: listItemBrighten
        color: root.pressed ? styleMusic.common.white : "transparent"
        opacity: 0.1
        height: root.height
        x: root.x - parent.x  // -parent.x due to selectionIcon in ListItemWithActions
        width: root.width
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

    Item {
        Connections {  // Only allow one ListItem to be swiping at any time
            target: mainView
            onListItemSwiping: {
                if (i !== index) {
                    root.resetSwipe();
                }
            }
        }

        Connections {  // Connections from signals in the ListView
            target: root.parent.parent
            onClearSelection: selected = false
            onFlickingChanged: {
                if (root.parent.parent.flicking) {
                    root.resetSwipe()
                }
            }
            onSelectAll: selected = true
            onStateChanged: selectionMode = root.parent.parent.state === "multiselectable"
        }
    }


    MusicRow {
        id: musicRow
        anchors {
            verticalCenter: parent.verticalCenter
        }
        height: parent.height
    }

    Component.onCompleted: {  // reload settings as delegates are destroyed
        if (parent.parent.selectedItems.indexOf(index) !== -1) {
            selected = true
        }

        selectionMode = root.parent.parent.state === "multiselectable"
    }
}
