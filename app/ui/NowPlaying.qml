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
import QtQuick.LocalStorage 2.0
import Ubuntu.Components 1.3
import "../components"
import "../components/HeadState"
import "../logic/meta-database.js" as Library
import "../logic/playlists.js" as Playlists

MusicPage {
    id: nowPlaying
    flickable: isListView ? queueListLoader.item : null  // Ensures that the header is shown in fullview
    hasSections: true
    objectName: "nowPlayingPage"
    showToolbar: false
    state: {
        if (isListView) {
            if (queueListLoader.item.state === "multiselectable") {
                "selection"
            } else {
                "default"
            }
        } else {
            "fullview"
        }
    }
    states: [
        // FIXME: fullview has its own state for now as changing the flickable
        // property sometimes causes the header to disappear
        QueueHeadState {
            stateName: "fullview"
            thisHeader {
                extension: Sections {
                    model: defaultStateSections.model
                    objectName: "nowPlayingSections"
                    selectedIndex: 0

                    onSelectedIndexChanged: {
                        if (selectedIndex == 1) {
                            isListView = !isListView;
                            selectedIndex = 0;
                        }
                    }
                }
                flickable: null
            }
            thisPage: nowPlaying
        },
        QueueHeadState {
            thisHeader {
                extension: Sections {
                    model: defaultStateSections.model
                    objectName: "nowPlayingSections"
                    selectedIndex: 1

                    onSelectedIndexChanged: {
                        if (selectedIndex == 0) {
                            isListView = !isListView;
                            selectedIndex = 1;
                        }
                    }
                }
                flickable: queueListLoader.item
            }
            thisPage: nowPlaying
        },
        MultiSelectHeadState {
            addToQueue: false
            listview: queueListLoader.item
            removable: true
            thisHeader {
                extension: Sections {
                    model: defaultStateSections.model
                    objectName: "nowPlayingSections"
                    selectedIndex: 1

                    onSelectedIndexChanged: {
                        if (selectedIndex == 0) {
                            isListView = !isListView;
                            selectedIndex = 1;
                        }
                    }
                }
            }
            thisPage: nowPlaying

            onRemoved: {
                // Remove the tracks from the queue
                // Use slice() to copy the list
                // so that the indexes don't change as they are removed
                player.mediaPlayer.playlist.removeItemsWrapper(selectedIndices.slice());
            }
        }
    ]
    title: nowPlayingTitle

    property bool isListView: false
    // TRANSLATORS: this appears in the header with limited space (around 20 characters)
    property string nowPlayingTitle: i18n.tr("Now playing") 
    // TRANSLATORS: this appears in the header with limited space (around 20 characters)
    property string fullViewTitle: i18n.tr("Full view") 
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
        } else {
            // Close multiselection mode.
            queueListLoader.item.closeSelection()
        }
    }
    onVisibleChanged: {
        if (wideAspect) {
            popWaitTimer.start()
        }
    }

    Timer {  // FIXME: workaround for when entering wideAspect coming back from a stacked page (AddToPlaylist) and the page being deleted breaks the stacked page
        id: popWaitTimer
        interval: 250
        onTriggered: mainPageStack.popPage(nowPlaying);
    }

    PageHeadSections {
        id: defaultStateSections
        model: [fullViewTitle, queueTitle]

        onSelectedIndexChanged: isListView = selectedIndex == 1

        // Set at startup to avoid binding loop
        Component.onCompleted: selectedIndex = isListView ? 1 : 0
    }

    // Ensure that the listview has loaded before attempting to positionAt
    function ensureListViewLoaded() {
        if (queueListLoader.item.count === player.mediaPlayer.playlist.itemCount) {
            positionAt(player.mediaPlayer.playlist.currentIndex);
        } else {
            queueListLoader.item.onCountChanged.connect(function() {
                if (queueListLoader.item.count === player.mediaPlayer.playlist.itemCount) {
                    positionAt(player.mediaPlayer.playlist.currentIndex);
                }
            })
        }
    }

    // Position the view at the index
    function positionAt(index) {
        queueListLoader.item.positionViewAtIndex(index, ListView.Center);
    }

    function setListView(listView) {
        defaultStateSections.selectedIndex = listView ? 1 : 0;
    }

    Loader {
        anchors {
            bottom: nowPlayingToolbarLoader.top
            left: parent.left
            right: parent.right
            top: nowPlaying.header.bottom
        }
        source: "../components/NowPlayingFullView.qml"
        visible: !isListView
    }

    Loader {
        id: queueListLoader
        anchors {
            bottom: nowPlayingToolbarLoader.top
            left: parent.left
            right: parent.right
            top: parent.top  // Don't use header.bottom otherwise flickery
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

    Connections {
        target: mainView
        onWideAspectChanged: {
            // Do not pop if not visible (eg on AddToPlaylist)
            if (wideAspect && nowPlaying.visible) {
                mainPageStack.popPage(nowPlaying);
            }
        }
    }

    Connections {
        target: player.mediaPlayer.playlist
        onEmptyChanged: {
            if (player.mediaPlayer.playlist.empty) {
                mainPageStack.goBack()
            }
        }
    }
}
