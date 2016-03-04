/*
 * Copyright (C) 2013, 2014, 2015, 2016
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
import Ubuntu.Components 1.3

import "HeadState"

Rectangle {
    id: nowPlayingSidebar
    anchors {
        fill: parent
    }
    color: "#2c2c34"
    state: queue.state === "multiselectable" ? "selection" : "default"
    states: [
        QueueHeadState {
            thisHeader {
                leadingActionBar {
                    actions: []  // hide tab bar
                }
                z: 100  // put on top of content
            }
            thisPage: nowPlayingSidebar
        },
        MultiSelectHeadState {
            addToQueue: false
            listview: queue
            removable: true
            thisHeader {
                z: 100  // put on top of content
            }
            thisPage: nowPlayingSidebar

            onRemoved: {
                // Remove the tracks from the queue
                // Use slice() to copy the list
                // so that the indexes don't change as they are removed
                player.mediaPlayer.playlist.removeItemsWrapper(selectedIndices.slice());
            }
        }
    ]
    property alias flickable: queue  // fake normal Page
    property Item header: PageHeader {
        id: pageHeader
        leadingActionBar {
            actions: nowPlayingSidebar.head.backAction
        }
        flickable: queue
        trailingActionBar {
            actions: nowPlayingSidebar.head.actions
        }
        z: 100  // put on top of content

        StyleHints {
            backgroundColor: mainView.headerColor
        }
    }
    property Item previousHeader: null
    property string title: ""  // fake normal Page

    onHeaderChanged: {  // Copy what SDK does to parent header correctly
        if (previousHeader) {
            previousHeader.parent = null
        }

        header.parent = nowPlayingSidebar
        previousHeader = header;
    }

    Loader {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        height: units.gu(6.125)
        sourceComponent: header
    }

    Queue {
        id: queue
        anchors {
            bottomMargin: 0
            topMargin: 0
        }
        clip: true
        isSidebar: true
        header: Column {
            id: sidebarColumn
            anchors {
                left: parent.left
                right: parent.right
            }

            NowPlayingFullView {
                anchors {
                    fill: undefined
                }
                backgroundColor: "#2c2c34"
                clip: true
                height: units.gu(47)
                sidebar: true
                width: parent.width
            }

            NowPlayingToolbar {
                anchors {
                    fill: undefined
                }
                bottomProgressHint: false
                color: "#2c2c34"
                height: itemSize + 2 * spacing + units.gu(2)
                width: parent.width
            }
        }
    }
}
