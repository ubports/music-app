/*
 * Copyright (C) 2013, 2014, 2015
 *      Andrew Hayzen <ahayzen@gmail.com>
 *      Daniel Holm <d.holmen@gmail.com>
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

MusicListView {
    property var selectedItems: []

    signal clearSelection()
    signal closeSelection()
    signal selectAll()

    onClearSelection: selectedItems = []
    onCloseSelection: {
        clearSelection()
        state = "normal"
    }
    onSelectAll: {
        var tmp = selectedItems

        for (var i=0; i < model.count; i++) {
            if (tmp.indexOf(i) === -1) {
                tmp.push(i)
            }
        }

        selectedItems = tmp
    }
    onVisibleChanged: {
        if (!visible) {
            closeSelection()
        }
    }
}
