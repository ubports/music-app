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


GridView {
    anchors {
        fill: parent
        rightMargin: card.margin
        bottomMargin: card.margin
    }
    cellWidth: width / parseInt(width / units.gu(15))  // 15 GU minimum
    cellHeight: cellWidth + card.columnLabelHeight
    displaced: Transition {  // Animate when items are added/moved/removed
        UbuntuNumberAnimation {
            properties: "x,y"
        }
    }
    flow: GridView.LeftToRight

    Card {  // Empty object to calculate margin/height
        id: card
        visible: false
    }
}
