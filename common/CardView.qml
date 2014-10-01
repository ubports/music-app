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
    contentWidth: parent.width;
    contentHeight: flow.childrenRect.height

    property int cellWidth: flow.width / parseInt(flow.width / units.gu(15)) - units.gu(2)  // 15 GU minimum
    property alias delegate: flowRepeater.delegate
    property alias model: flowRepeater.model

    Flow {
        id: flow
        anchors {
            fill: parent
            leftMargin: units.gu(2)
            topMargin: units.gu(2)
        }
        flow: Flow.LeftToRight
        spacing: units.gu(2)

        Repeater {
            id: flowRepeater
        }
    }
}

