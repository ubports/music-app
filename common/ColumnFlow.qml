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

Item {
    id: columnFlow
    property int columns: 1
    property Flickable flickable
    property var model
    property Component delegate

    property var getter: function (i) { return model.get(i); }  // optional getter override (useful for music-app ms2 models)

    property int buffer: units.gu(20)
    property var columnHeights: []
    property var columnHeightsMax: []
    property int columnWidth: parent.width / columns
    property int contentHeight: 0
    property int count: model === undefined ? 0 : model.count
    property var incubating: ({})  // incubating objects
    property var items: ({})
    property var itemToColumn: ({})  // cache of the columns of indexes
    property int lastIndex: 0  // the furtherest index loaded

    onColumnWidthChanged: {
        if (columns != columnHeights.length) {  // number of columns has changed so reset
            reset()
            append()
        } else {  // column width has changed update visible items properties linked to columnWidth
            for (var column=0; column < columnHeights.length; column++) {
                for (var i in columnHeights[column]) {
                    if (columnHeights[column].hasOwnProperty(i) && items.hasOwnProperty(i)) {
                        items[i].width = columnWidth;
                        items[i].x = column * columnWidth;
                    }
                }
            }
        }
    }

    onCountChanged: {
        if (count === 0) {  // likely the model is been reset so reset the view
            reset()
        } else {  // likely new items in the model check if any can be shown
            append()
        }
    }

    // Append a new row of items if possible
    function append()
    {
        // Do not allow append to run if incubating
        if (isIncubating() === true) {
            return;
        }

        // get the columns in order
        var columnsByHeight = getColumnsByHeight();

        // check if a new item in each column is possible
        for (var i=0; i < columnsByHeight.length; i++) {
            var y = columnHeightsMax[columnsByHeight[i]];

            // build new object in column if possible
            if (count > 0 && lastIndex < count && inViewport(y, 0)) {
                incubateObject(lastIndex++, columnsByHeight[i], getMaxVisibleInColumn(columnsByHeight[i]), append);
            } else {
                break;
            }
        }
    }

    // Cache the size of the columns for use later
    function cacheColumnHeights()
    {
        columnHeightsMax = [];

        for (var i=0; i < columnHeights.length; i++) {
            var sum = 0;

            for (var j in columnHeights[i]) {
                sum += columnHeights[i][j];
            }

            columnHeightsMax.push(sum);
        }

        // set the height of columnFlow to max column (for flickable contentHeight)
        contentHeight = Math.max.apply(null, columnHeightsMax);
    }

    // Recache the visible items heights (due to a change in their height)
    function cacheVisibleItemsHeights()
    {
        for (var i in items) {
            if (items.hasOwnProperty(i)) {
                columnHeights[itemToColumn[i]][i] = items[i].height;
            }
        }

        cacheColumnHeights();
    }

    // Return if there are incubating objects
    function isIncubating()
    {
        for (var i in incubating) {
            if (incubating.hasOwnProperty(i)) {
                return true;
            }
        }

        return false;
    }

    // Run after incubation to store new column height and call any further append/restores
    function finishIncubation(index, callback)
    {
        var obj = incubating[index].object;
        delete incubating[index];

        obj.heightChanged.connect(cacheVisibleItemsHeights)  // if the height changes recache

        // Ensure properties linked to columnWidth are correct (as width may still be changing)
        obj.x = itemToColumn[index] * columnWidth;
        obj.width = columnWidth;

        items[index] = obj;

        columnHeights[itemToColumn[index]][index] = obj.height;  // ensure height is the latest

        if (isIncubating() === false) {
            cacheColumnHeights();

            // Check if there is any more work to be done (append or restore)
            callback();
        }
    }

    // Get the column index in order of height
    function getColumnsByHeight()
    {
        var columnsByHeight = [];

        for (var i=0; i < columnHeightsMax.length; i++) {
            var min = undefined;
            var index = -1;

            // Find the smallest column that has not been found yet
            for (var j=0; j < columnHeightsMax.length; j++) {
                if (columnsByHeight.indexOf(j) === -1 && (min === undefined || columnHeightsMax[j] < min)) {
                    min = columnHeightsMax[j];
                    index = j;
                }
            }

            columnsByHeight.push(index);
        }

        return columnsByHeight;
    }

    // Get the min value in a column after the limit
    function getMinIndexInColumnAfter(column, limit)
    {
        for (var i=limit + 1; i <= lastIndex; i++) {
            if (columnHeights[column].hasOwnProperty(i)) {
                return i;
            }
        }
    }

    // Get the lowest visible index for a column
    function getMinVisibleInColumn(column)
    {
        var min;

        for (var i in columnHeights[column]) {
            if (columnHeights[column].hasOwnProperty(i)) {
                i = parseInt(i);

                if (items.hasOwnProperty(i)) {
                    if (i < min || min === undefined) {
                        min = i;
                    }
                }
            }
        }

        return min;
    }

    // Get the max value in a column before the limit
    function getMaxIndexInColumnBefore(column, limit)
    {
        for (var i=--limit; i >= 0; i--) {
            if (columnHeights[column].hasOwnProperty(i)) {
                return i;
            }
        }
    }

    // Get the highest visible index for a column
    function getMaxVisibleInColumn(column)
    {
        var max;

        for (var i in columnHeights[column]) {
            if (columnHeights[column].hasOwnProperty(i)) {
                i = parseInt(i);

                if (items.hasOwnProperty(i)) {
                    if (i > max || max === undefined) {
                        max = i;
                    }
                }
            }
        }

        return max;
    }

    // Incubate an object for creation
    function incubateObject(index, column, anchorIndex, callback)
    {
        // Load parameters to send to the object on creation
        var params = {
            index: index,
            model: getter(index),
            width: columnWidth,
            x: column * columnWidth
        };

        if (anchorIndex === undefined) {
            params["anchors.top"] = parent.top;
        } else if (anchorIndex < 0) {
            params["anchors.bottom"] = items[-(anchorIndex + 1)].top;
        } else {
            params["anchors.top"] = items[anchorIndex].bottom;
        }

        // Start incubating and cache the column
        incubating[index] = delegate.incubateObject(parent, params);
        itemToColumn[index] = column;

        if (incubating[index].status != Component.Ready) {
            incubating[index].onStatusChanged = function(status) {
                if (status == Component.Ready) {
                    finishIncubation(index, callback)
                }
            }
        } else {
            finishIncubation(index, callback)
        }
    }

    // Detect if a loaded object is in the viewport with double buffer before and single after
    function inViewport(y, height)
    {
        return flickable.contentY - buffer - buffer < y + height && y < flickable.contentY + flickable.height + buffer;
    }

    // Reset the column flow
    function reset()
    {
        // Force and incubation to finish
        for (var i in incubating) {
            if (incubating.hasOwnProperty(i)) {
                incubating[i].forceCompletion()
            }
        }

        // Destroy any old items
        for (var j in items) {
            if (items.hasOwnProperty(j)) {
                items[j].destroy()
            }
        }

        // Reset and rebuild the variables
        items = ({})
        lastIndex = 0

        columnHeights = []

        for (var k=0; k < columns; k++) {
            columnHeights.push({})
        }

        cacheColumnHeights()

        contentHeight = 0
    }

    // Restore any objects that are now in the viewport
    function restore()
    {
        // Do not allow restore to run if incubating
        if (isIncubating() === true) {
            return;
        }

        for (var column in columnHeights) {
            var index;

            // Rebuild anything before the lowest visible index
            var minVisible = getMinVisibleInColumn(column);

            if (minVisible !== undefined) {
                // get the next lowest index for this column to add before
                index = getMaxIndexInColumnBefore(column, minVisible)

                if (index !== undefined) {
                    // Check that the object will be in the viewport
                    if (inViewport(items[minVisible].y - columnHeights[column][index], columnHeights[column][index])) {
                        incubateObject(index, column, (-minVisible) - 1, restore)  // add the new object
                    }
                }
            }

            // Rebuild anything after the highest visible index
            var maxVisible = getMaxVisibleInColumn(column);

            if (maxVisible !== undefined) {
                // get the next highest index for this column to add after
                index = getMinIndexInColumnAfter(column, maxVisible);

                if (index !== undefined) {
                    // Check that the object will be in the viewport
                    if (inViewport(items[maxVisible].y + columnHeights[column][maxVisible], columnHeights[column][index])) {
                        incubateObject(index, column, maxVisible, restore)  // add the new object
                    }
                }
            }
        }
    }

    Connections {
        target: flickable
        onContentYChanged: {
            restore()  // Restore old items (scrolling up/down)

            append()  // Append any new items (scrolling down)

            // skip if at the start of end of the flickable (prevents overscroll issue)
            if (!flickable.atYBeginning && !flickable.atYEnd) {
                // Destroy any old items
                for (var i in items) {
                    if (items.hasOwnProperty(i)) {
                        if (!inViewport(items[i].y, items[i].height)) {
                            // Ensure height is at its latest value
                            columnHeights[itemToColumn[i]][items[i].index] = items[i].height;

                            // Destroy the object
                            items[i].destroy()
                            delete items[i];
                        }
                    }
                }
            }
        }
    }
}
