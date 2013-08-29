/*
 * Copyright (C) 2013 Andrew Hayzen <ahayzen@gmail.com>
 *                    Daniel Holm <d.holmen@gmail.com>
 *                    Victor Thompson <victor.thompson@gmail.com>
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

import QtQuick 2.0
import Ubuntu.Components 0.1

Rectangle {
    anchors.fill: parent
    color: styleMusic.mainView.backgroundColor

    Label {
        id: swipeBackgroundText
        anchors.fill: parent
        anchors.margins: units.gu(2)
        color: styleMusic.common.white
        fontSize: "large"
        text: parent.text
        verticalAlignment: Text.AlignVCenter
    }

    states: [
        State {
            name: "SwipingRight"
            PropertyChanges {
                target: swipeBackgroundText
                horizontalAlignment: Text.AlignRight
            }
        },

        State {
            name: "SwipingLeft"
            PropertyChanges {
                target: swipeBackgroundText
                horizontalAlignment: Text.AlignLeft
            }
        }
    ]
}
