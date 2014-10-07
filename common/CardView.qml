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


Flickable {
    anchors {
        fill: parent
        margins: units.gu(1)
    }

    // dont use flow.contentHeight as it is inaccurate due to height of labels
    // changing as they load
    contentHeight: flow.childrenRect.height
    contentWidth: width

    property alias delegate: flow.delegate
    property alias model: flow.model

    ColumnFlow {
        id: flow
        columns: parseInt(width / units.gu(15))
        width: parent.width
    }
}
