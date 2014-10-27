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
    }

    // dont use flow.contentHeight as it is inaccurate due to height of labels
    // changing as they load
    contentHeight: headerLoader.childrenRect.height + flowContainer.height
    contentWidth: width

    property alias count: flow.count
    property alias delegate: flow.delegate
    property alias header: headerLoader.sourceComponent
    property var model: flow.model
    property real itemWidth: units.gu(15)

    onVisibleChanged: {
        if (visible) {  // only load model once CardView is visible
            flow.model = model
        }
    }

    Loader {
        id: headerLoader
        asynchronous: true
        visible: sourceComponent !== undefined
        width: parent.width
    }

    Item {
        id: flowContainer
        anchors {
            top: headerLoader.bottom
        }
        height: flow.childrenRect.height + flow.anchors.margins * 2
        width: parent.width

        ColumnFlow {
            id: flow
            anchors {
                fill: parent
                margins: units.gu(1)
            }
            columns: parseInt(width / itemWidth)
        }
    }
}
