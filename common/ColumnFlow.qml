/*
 * Copyright (C) 2014
 *      Andrew Hayzen <ahayzen@gmail.com>
 *      Michael Spencer <sonrisesoftware@gmail.com>
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


Item {
    id: columnFlow
    property int columns: 1
    property bool repeaterCompleted: false
    property alias model: repeater.model
    property alias delegate: repeater.delegate
    property int contentHeight: 0

    onColumnsChanged: reEvalColumns()
    onModelChanged: reEvalColumns()
    onWidthChanged: updateWidths()

    function updateWidths() {
        if (repeaterCompleted) {
            var count = 0

            //add the first <column> elements
            for (var i = 0; count < columns && i < columnFlow.children.length; i++) {
                //print(i, count)
                if (!columnFlow.children[i] || String(columnFlow.children[i]).indexOf("QQuickRepeater") == 0)
                        //|| !columnFlow.children[i].visible)  // CUSTOM - view is invisible at start
                    continue

                columnFlow.children[i].width = width / columns

                count++
            }
        }
    }

    function reEvalColumns() {
        if (columnFlow.repeaterCompleted === false)
            return

        if (columns === 0) {
            contentHeight = 0
            return
        }

        var i, j
        var columnHeights = new Array(columns);
        var lastItem = new Array(columns)
        var lastI = -1
        var count = 0

        //add the first <column> elements
        for (i = 0; count < columns && i < columnFlow.children.length; i++) {
            if (!columnFlow.children[i] || String(columnFlow.children[i]).indexOf("QQuickRepeater") == 0)
                    //|| !columnFlow.children[i].visible)  // CUSTOM - view is invisible at start
                continue

            lastItem[count] = i

            columnHeights[count] = columnFlow.children[i].height
            columnFlow.children[i].anchors.top = columnFlow.top
            columnFlow.children[i].anchors.left = (lastI === -1 ? columnFlow.left : columnFlow.children[lastI].right)
            columnFlow.children[i].anchors.right = undefined
            columnFlow.children[i].width = columnFlow.width / columns

            lastI = i
            count++
        }

        //add the other elements
        for (i = i; i < columnFlow.children.length; i++) {
            var highestHeight = Number.MAX_VALUE
            var newColumn = 0

            if (!columnFlow.children[i] || String(columnFlow.children[i]).indexOf("QQuickRepeater") == 0)
                    //|| !columnFlow.children[i].visible)  // CUSTOM - view is invisible at start
                continue

            // find the shortest column
            for (j = 0; j < columns; j++) {
                if (columnHeights[j] !== null && columnHeights[j] < highestHeight) {
                    newColumn = j
                    highestHeight = columnHeights[j]
                }
            }

            // add the element to the shortest column
            columnFlow.children[i].anchors.top = columnFlow.children[lastItem[newColumn]].bottom
            columnFlow.children[i].anchors.left = columnFlow.children[lastItem[newColumn]].left
            columnFlow.children[i].anchors.right = columnFlow.children[lastItem[newColumn]].right

            lastItem[newColumn] = i
            columnHeights[newColumn] += columnFlow.children[i].height
        }

        var cHeight = 0

        for (i = 0; i < columnHeights.length; i++) {
            if (columnHeights[i])
                cHeight = Math.max(cHeight, columnHeights[i])
        }

        contentHeight = cHeight
        updateWidths()
    }

    Repeater {
        id: repeater
        model: columnFlow.model
        Component.onCompleted: {
            columnFlow.repeaterCompleted = true
            columnFlow.reEvalColumns()
        }
        onItemAdded: columnFlow.reEvalColumns()  // CUSTOM - ms2 models are live
        onItemRemoved: columnFlow.reEvalColumns()  // CUSTOM - ms2 models are live
    }
}
