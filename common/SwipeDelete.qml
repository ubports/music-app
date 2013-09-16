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

/* SwipeDelete object */
Rectangle {
    id: swipeBackground
    color: styleMusic.mainView.backgroundColor
    height: parent.height
    state: "normal"
    width: parent.width
    x: parent.width  // start out of view

    states: [
        State {
            name: "normal"
            PropertyChanges {
                target: swipeBackgroundText
                visible: false
            }
        },

        State {
            name: "swipingRight"
            PropertyChanges {
                target: swipeBackgroundText
                horizontalAlignment: Text.AlignRight
                visible: true
            }
        },

        State {
            name: "swipingLeft"
            PropertyChanges {
                target: swipeBackgroundText
                horizontalAlignment: Text.AlignLeft
                visible: true
            }
        },

        State {
            name: "reorder"
            PropertyChanges {
                target: swipeBackgroundText
                visible: false
            }
        }
    ]

    Label {
        id: swipeBackgroundText
        anchors.fill: parent
        anchors.margins: units.gu(2)
        color: styleMusic.common.white
        fontSize: "large"
        text: i18n.tr("Clear")
        verticalAlignment: Text.AlignVCenter
        visible: false
    }

    /*
     * Animation to reset the swipe object
     *   when not dragged far enough (hence opposite direction to swipe)
     *
     * If swipingLeft the item leaves to the right
     * If swipingRight it leaves to the left
     */
    NumberAnimation {
        id: swipeResetAnimation
        target: swipeBackground
        properties: "x"
        to: parent.state == "swipingLeft" ? parent.width : 0 - swipeBackground.width
        duration: swipeDelete.transitionDuration
    }

    /*
     * Animation to prepare the swipe object for removal
     * This animation moves the swipe object into the centre of the display
     */
    NumberAnimation {
        id: swipePrepareDeleteAnimation
        target: swipeBackground
        properties: "x"
        to: 0
        duration: swipeDelete.transitionDuration
    }

    /*
     * Animation to remove the swipe object
     * - Reduces the height to 0 to 'pull up' the row below
     * - On animation finish it removes the item from the model
     */
    NumberAnimation {
        id: swipeDeleteAnimation
        target: swipeBackground
        properties: "height,x"
        to: 0
        duration: swipeDelete.transitionDuration

        onRunningChanged: {
            if (running == false)
            {
                // Reset the position offscreen and the height
                swipeBackground.x = parent.width;
                swipeBackground.height = parent.height;

                swipeDelete.removeIndex(index);
            }

            swipeBackgroundText.visible = !running;  // set the visibility
        }
    }
}
