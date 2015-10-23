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
import QtQuick.LocalStorage 2.0
import Ubuntu.Components 1.3
import "../components"
import "../components/HeadState"
import "../logic/meta-database.js" as Library
import "../logic/playlists.js" as Playlists

MusicPage {
    id: nowPlaying
    flickable: isListView ? queueListLoader.item : null  // Ensures that the header is shown in fullview
    objectName: "nowPlayingPage"
    showToolbar: false
    title: isListView ? queueTitle : nowPlayingTitle
    visible: false

    property bool isListView: false
    // TRANSLATORS: this appears in the header with limited space (around 20 characters)
    property string nowPlayingTitle: i18n.tr("Now playing") 
    // TRANSLATORS: this appears in the header with limited space (around 20 characters)
    property string queueTitle: i18n.tr("Queue") 

    onIsListViewChanged: {
        if (isListView) {  // When changing to the queue positionAt the currentIndex
            // ensure the loader and listview is ready
            if (queueListLoader.status === Loader.Ready) {
                ensureListViewLoaded()
            } else {
                queueListLoader.onStatusChanged.connect(function() {
                    if (queueListLoader.status === Loader.Ready) {
                        ensureListViewLoaded()
                    }
                })
            }
        }
    }

    // Ensure that the listview has loaded before attempting to positionAt
    function ensureListViewLoaded() {
        if (queueListLoader.item.count === trackQueue.model.count) {
            positionAt(player.currentIndex);
        } else {
            queueListLoader.item.onCountChanged.connect(function() {
                if (queueListLoader.item.count === trackQueue.model.count) {
                    positionAt(player.currentIndex);
                }
            })
        }
    }

    // Position the view at the index
    function positionAt(index) {
        queueListLoader.item.positionViewAtIndex(index, ListView.Center);
    }

    state: isListView && queueListLoader.item.state === "multiselectable" ? "selection" : "default"
    states: [
        PageHeadState {
            id: defaultState

            name: "default"
            actions: [
                Action {
                    objectName: "toggleView"
                    iconName: isListView ? "stock_image" : "view-list-symbolic"
                    onTriggered: {
                        isListView = !isListView
                    }
                },
                Action {
                    enabled: trackQueue.model.count > 0
                    iconName: "add-to-playlist"
                    // TRANSLATORS: this action appears in the overflow drawer with limited space (around 18 characters)
                    text: i18n.tr("Add to playlist")
                    onTriggered: {
                        var items = []

                        items.push(makeDict(trackQueue.model.get(player.currentIndex)));

                        mainPageStack.push(Qt.resolvedUrl("AddToPlaylist.qml"),
                                           {"chosenElements": items})
                    }
                },
                Action {
                    enabled: trackQueue.model.count > 0
                    iconName: "delete"
                    objectName: "clearQueue"
                    // TRANSLATORS: this action appears in the overflow drawer with limited space (around 18 characters)
                    text: i18n.tr("Clear queue")
                    onTriggered: {
                        mainPageStack.goBack()
                        trackQueue.clear()
                    }
                }
            ]
            PropertyChanges {
                target: nowPlaying.head
                backAction: defaultState.backAction
                actions: defaultState.actions
            }
        },
        MultiSelectHeadState {
            addToQueue: false
            listview: queueListLoader.item
            removable: true
            thisPage: nowPlaying

            onRemoved: {
                // Remove the tracks from the queue
                // Use slice() to copy the list
                // so that the indexes don't change as they are removed
                trackQueue.removeQueueList(selectedItems.slice())
            }
        }
    ]

    Loader {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: headerHeight
        }

        property real headerHeight: units.gu(6)

        height: parent.height - headerHeight - units.gu(9.5)
        source: "../components/NowPlayingFullView.qml"
        visible: !isListView
    }

    Loader {
        id: queueListLoader
        anchors {
            bottomMargin: nowPlayingToolbarLoader.height + units.gu(2)
            fill: parent
            topMargin: units.gu(2)
        }
        asynchronous: true
        source: "../components/Queue.qml"
        visible: isListView
    }

    Loader {
        id: nowPlayingToolbarLoader
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        height: units.gu(10)
        source: "../components/NowPlayingToolbar.qml"
    }
}
