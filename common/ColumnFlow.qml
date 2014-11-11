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
    property bool restoring: false  // is the view restoring?
    property var restoreItems: ({})  // when rebuilding items are stored here temporarily

    onColumnWidthChanged: {
        if (restoring) {
            return;
        }
        else if (columns != columnHeights.length && visible) {
            // number of columns has changed so rebuild the columns
            rebuildColumns()
        } else {  // column width has changed update visible items properties linked to columnWidth
            for (var column=0; column < columnHeights.length; column++) {
                for (var i in columnHeights[column]) {
                    if (columnHeights[column].hasOwnProperty(i) && items.hasOwnProperty(i)) {
                        items[i].width = columnWidth;
                        items[i].x = column * columnWidth;
                    }
                }
            }

            ensureItemsVisible()
        }
    }

    onCountChanged: {
        if (!visible) {  // store changes for when visible
            if (count === 0 && lastIndex > -1) {
                lastIndex = -1;
            } else if (lastIndex > -1) {
                lastIndex = -(lastIndex + 2);  // save the index to restore later
            }
        } else if (count === 0) {  // likely the model is been reset so reset the view
            reset()
        } else {  // likely new items in the model check if any can be shown
            append()
        }
    }

    onVisibleChanged: {
        if (columns != columnHeights.length && visible) {  // number of columns has changed while invisible so reset
            if (!restoring) {
                rebuildColumns()
            }
        } else if (lastIndex < 0 && visible) {  // restore from count change
            if (lastIndex === -1) {
                reset()
            } else {
                lastIndex = (-lastIndex) - 2
            }

            append()
        }
    }

    // Append a new row of items if possible
    function append()
    {
        // Do not allow append to run if incubating
        if (isIncubating() || restoring) {
            return;
        }

        // get the columns in order
        var columnsByHeight = getColumnsByHeight();
        var workDone = false;

        // check if a new item in each column is possible
        for (var i=0; i < columnsByHeight.length; i++) {
            var y = columnHeightsMax[columnsByHeight[i]];

            // build new object in column if possible
            if (count > 0 && lastIndex < count && inViewport(y, 0)) {
                incubateObject(lastIndex++, columnsByHeight[i], getMaxInColumn(columnsByHeight[i]), append);
                workDone = true
            } else {
                break;
            }
        }

        if (!workDone) {  // last iteration over append so visible ensure items are correct
            ensureItemsVisible();
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

        if (!restoring) {  // when not restoring otherwise user will be pushed to the top of the view
            // set the height of columnFlow to max column (for flickable contentHeight)
            contentHeight = Math.max.apply(null, columnHeightsMax);
        }
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

    // Ensures that the correct items are visible
    function ensureItemsVisible()
    {
        for (var i in items) {
            if (items.hasOwnProperty(i)) {
                items[i].visible = inViewport(items[i].y, items[i].height)
            }
        }
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

        if (!isIncubating()) {
            cacheColumnHeights();

            // Check if there is any more work to be done (append or restore)
            callback();
        }
    }

    // Force any incubation to finish
    function forceIncubationCompletion()
    {
        for (var i in incubating) {
            if (incubating.hasOwnProperty(i)) {
                incubating[i].forceCompletion()
            }
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

    // Get the highest index for a column
    function getMaxInColumn(column)
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
            "anchors.top": anchorIndex === undefined ? parent.top : items[anchorIndex].bottom,
            index: index,
            model: getter(index),
            width: columnWidth,
            x: column * columnWidth
        };

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

    // Detect if a loaded object is in the viewport with a buffer
    function inViewport(y, height)
    {
        return flickable.contentY - buffer < y + height && y < flickable.contentY + flickable.height + buffer;
    }

    // Number of columns has changed rebuild with live items
    function rebuildColumns()
    {
        restoring = true;
        var i;

        forceIncubationCompletion()

        columnHeights = []
        columnHeightsMax = []

        for (i=0; i < columns; i++) {
            columnHeights.push({});
            columnHeightsMax.push(0);
        }

        lastIndex = 0;

        restoreItems = items;
        items = {};

        restoreExisting()

        restoring = false;

        cacheColumnHeights();  // rebuilds contentHeight

        // If the columns have changed while the view was locked rerun
        if (columns != columnHeights.length && visible) {
            rebuildColumns()
        } else {
            append()  // check if any new items can be added
        }
    }

    // Restores existing items into potentially new positions
    function restoreExisting()
    {
        var i;

        // get the columns in order
        var columnsByHeight = getColumnsByHeight();
        var workDone = false;

        // check if a new item in each column is possible
        for (i=0; i < columnsByHeight.length; i++) {
            var column = columnsByHeight[i];

            // build new object in column if possible
            if (count > 0 && lastIndex < count) {
                if (restoreItems.hasOwnProperty(lastIndex)) {
                    var item = restoreItems[lastIndex];
                    var maxInColumn = getMaxInColumn(column);  // get lowest item in column

                    itemToColumn[lastIndex] = column;
                    columnHeights[column][lastIndex] = item.height;  // ensure height is the latest

                    // Rebuild item properties
                    item.anchors.bottom = undefined
                    item.anchors.top = maxInColumn === undefined ? parent.top : items[maxInColumn].bottom;
                    item.x = column * columnWidth;
                    item.visible = inViewport(item.y, item.height);

                    // Migrate item from restoreItems to items
                    items[lastIndex] = item;
                    delete restoreItems[lastIndex];

                    // set after restore as height will likely change causing cacheVisibleItemsHeights to be run
                    item.width = columnWidth;

                    cacheColumnHeights();  // ensure column heights are up to date

                    lastIndex++;
                    workDone = true;
                }
            } else {
                break;
            }
        }

        if (workDone) {
            restoreExisting()  // if work done then check if any more is needed
        } else {
            restoreItems = {};  // ensure restoreItems is empty
        }
    }

    // Reset the column flow
    function reset()
    {
        forceIncubationCompletion()

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

    Connections {
        target: flickable
        onContentYChanged: {
            append()  // Append any new items (scrolling down)

            ensureItemsVisible()
        }
    }
}
