/*
 * Copyright (C) 2013, 2014, 2015
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

import QtQuick 2.4
import Ubuntu.Components 1.3


Item {
    id: actionReorder
    width: units.gu(4)

    Icon {
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }
        name: "navigation-menu"  // TODO: use proper image
        height: width
        width: units.gu(3)
        asynchronous: true
    }

    MouseArea {
        id: actionReorderMouseArea
        anchors {
            fill: parent
        }
        property int startY: 0
        property int startContentY: 0

        onPressed: {
            root.parent.parent.interactive = false;  // stop scrolling of listview
            startY = root.y;
            startContentY = root.parent.parent.contentY;
            root.z += 10;  // force ontop of other elements

            console.debug("Reorder listitem pressed", root.y)
        }
        onMouseYChanged: root.y += mouse.y - (root.height / 2);
        onReleased: {
            console.debug("Reorder diff by position", getDiff());

            var diff = getDiff();

            // Remove the height of the actual item if moved down
            if (diff > 0) {
                diff -= 1;
            }

            root.parent.parent.interactive = true;  // reenable scrolling

            var newIndex = index + diff;

            if (newIndex < 0) {
                newIndex = 0;
            } else if (newIndex > root.parent.parent.count - 1) {
                newIndex = root.parent.parent.count - 1;
            }

            if (index === newIndex) {
                // Nothing has changed so reset the item
                // z index is restored after animation
                resetListItemYAnimation.start();
            } else {
                root.z -= 10;  // restore z index
                reorder(index, newIndex)
            }
        }

        function getDiff() {
            // Get the amount of items that have been passed over (by centre)
            return Math.round((((root.y - startY) + (root.parent.parent.contentY - startContentY)) / root.height) + 0.5);
        }
    }

    SequentialAnimation {
        id: resetListItemYAnimation
        UbuntuNumberAnimation {
            target: root;
            property: "y";
            to: actionReorderMouseArea.startY
        }
        ScriptAction {
            script: {
                root.z -= 10;  // restore z index
            }
        }
    }
}
