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

import QtMultimedia 5.0
import QtQuick 2.3
import QtQuick.LocalStorage 2.0
import Ubuntu.Components 1.1
import Ubuntu.Thumbnailer 0.1
import "common"
import "common/ListItemActions"
import "common/Themes/Ambiance"
import "meta-database.js" as Library
import "playlists.js" as Playlists

MusicPage {
    id: nowPlaying
    flickable: isListView ? queueListLoader.item : null  // Ensures that the header is shown in fullview
    objectName: "nowPlayingPage"
    title: isListView ? i18n.tr("Queue") : i18n.tr("Now playing")
    visible: false

    property bool isListView: false

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
                    iconName: "swap"
                    onTriggered: {
                        isListView = !isListView
                    }
                },
                Action {
                    enabled: trackQueue.model.count > 0
                    iconName: "add-to-playlist"
                    text: i18n.tr("Add to playlist")
                    onTriggered: {
                        var items = []

                        items.push(makeDict(trackQueue.model.get(player.currentIndex)));

                        var comp = Qt.createComponent("MusicaddtoPlaylist.qml")
                        var addToPlaylist = comp.createObject(mainPageStack, {"chosenElements": items});

                        if (addToPlaylist == null) {  // Error Handling
                            console.log("Error creating object");
                        }

                        mainPageStack.push(addToPlaylist)
                    }
                },
                Action {
                    enabled: trackQueue.model.count > 0
                    iconName: "delete"
                    objectName: "clearQueue"
                    text: i18n.tr("Clear queue")
                    onTriggered: {
                        pageStack.pop()
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
        PageHeadState {
            id: selectionState

            name: "selection"
            backAction: Action {
                text: i18n.tr("Cancel selection")
                iconName: "back"
                onTriggered: {
                    queueListLoader.item.clearSelection()
                    queueListLoader.item.state = "normal"
                }
            }
            actions: [
                Action {
                    text: i18n.tr("Select All")
                    iconName: "select"
                    onTriggered: {
                        if (queueListLoader.item.selectedItems.length === trackQueue.model.count) {
                            queueListLoader.item.clearSelection()
                        } else {
                            queueListLoader.item.selectAll()
                        }
                    }
                },
                Action {
                    enabled: queueListLoader.item.selectedItems.length > 0
                    iconName: "add-to-playlist"
                    text: i18n.tr("Add to playlist")
                    onTriggered: {
                        var items = []

                        for (var i=0; i < queueListLoader.item.selectedItems.length; i++) {
                            items.push(makeDict(trackQueue.model.get(queueListLoader.item.selectedItems[i])));
                        }

                        var comp = Qt.createComponent("MusicaddtoPlaylist.qml")
                        var addToPlaylist = comp.createObject(mainPageStack, {"chosenElements": items});

                        if (addToPlaylist == null) {  // Error Handling
                            console.log("Error creating object");
                        }

                        mainPageStack.push(addToPlaylist)

                        queueListLoader.item.closeSelection()
                    }
                },
                Action {
                    enabled: queueListLoader.item.selectedItems.length > 0
                    iconName: "delete"
                    text: i18n.tr("Delete")
                    onTriggered: {
                        // Remove the tracks from the queue
                        // Use slice() to copy the list
                        // so that the indexes don't change as they are removed
                        trackQueue.removeQueueList(queueListLoader.item.selectedItems.slice())

                        queueListLoader.item.closeSelection()
                    }
                }
            ]
            PropertyChanges {
                target: nowPlaying.head
                backAction: selectionState.backAction
                actions: selectionState.actions
            }
        }
    ]

    Item {
        id: fullview
        anchors.fill: parent
        visible: !isListView

        BlurredBackground {
            id: blurredBackground
            anchors.top: parent.top
            anchors.topMargin: mainView.header.height
            height: units.gu(27)
            art: albumImage.firstSource

            CoverGrid {
                id: albumImage
                anchors {
                    centerIn: parent
                }
                covers: [{art: player.currentMetaArt, author: player.currentMetaArtist, album: player.currentMetaAlbum}]
                size: units.gu(18)
            }
        }

        /* Full toolbar */
        Item {
            id: musicToolbarFullContainer
            anchors.top: blurredBackground.bottom
            anchors.topMargin: nowPlayingWideAspectTitle.lineCount === 1 ? units.gu(4) : units.gu(2)
            width: blurredBackground.width

            /* Column for labels in wideAspect */
            Column {
                id: nowPlayingWideAspectLabels
                spacing: units.gu(1)
                anchors {
                    left: parent.left
                    leftMargin: units.gu(2)
                    right: parent.right
                    rightMargin: units.gu(2)
                }

                /* Title of track */
                Label {
                    id: nowPlayingWideAspectTitle
                    anchors {
                        left: parent.left
                        leftMargin: units.gu(1)
                        right: parent.right
                        rightMargin: units.gu(1)
                    }
                    color: styleMusic.playerControls.labelColor
                    elide: Text.ElideRight
                    fontSize: "x-large"
                    maximumLineCount: 2
                    objectName: "playercontroltitle"
                    text: trackQueue.model.count === 0 ? "" : player.currentMetaTitle === "" ? player.currentMetaFile : player.currentMetaTitle
                    wrapMode: Text.WordWrap
                }

                /* Artist of track */
                Label {
                    id: nowPlayingWideAspectArtist
                    anchors {
                        left: parent.left
                        leftMargin: units.gu(1)
                        right: parent.right
                        rightMargin: units.gu(1)
                    }
                    color: styleMusic.nowPlaying.labelSecondaryColor
                    elide: Text.ElideRight
                    fontSize: "small"
                    text: trackQueue.model.count === 0 ? "" : player.currentMetaArtist
                }
            }

            /* Progress bar component */
            MouseArea {
                id: musicToolbarFullProgressContainer
                anchors.left: parent.left
                anchors.leftMargin: units.gu(3)
                anchors.right: parent.right
                anchors.rightMargin: units.gu(3)
                anchors.top: nowPlayingWideAspectLabels.bottom
                anchors.topMargin: nowPlayingWideAspectTitle.lineCount === 1 ? units.gu(3) : units.gu(1.5)
                height: units.gu(3)
                width: parent.width

                /* Position label */
                Label {
                    id: musicToolbarFullPositionLabel
                    anchors.top: progressSliderMusic.bottom
                    anchors.topMargin: units.gu(-2)
                    anchors.left: parent.left
                    color: styleMusic.nowPlaying.labelSecondaryColor
                    fontSize: "small"
                    height: parent.height
                    horizontalAlignment: Text.AlignHCenter
                    text: durationToString(player.position)
                    verticalAlignment: Text.AlignVCenter
                    width: units.gu(3)
                }

                Slider {
                    id: progressSliderMusic
                    anchors.left: parent.left
                    anchors.right: parent.right
                    maximumValue: player.duration  // load value at startup
                    objectName: "progressSliderShape"
                    style: UbuntuBlueSliderStyle {}
                    value: player.position  // load value at startup

                    function formatValue(v) {
                        if (seeking) {  // update position label while dragging
                            musicToolbarFullPositionLabel.text = durationToString(v)
                        }

                        return durationToString(v)
                    }

                    property bool seeking: false
                    property bool seeked: false

                    onSeekingChanged: {
                        if (seeking === false) {
                            musicToolbarFullPositionLabel.text = durationToString(player.position)
                        }
                    }

                    onPressedChanged: {
                        seeking = pressed

                        if (!pressed) {
                            seeked = true
                            player.seek(value)

                            musicToolbarFullPositionLabel.text = durationToString(value)
                       }
                    }

                    Connections {
                        target: player
                        onPositionChanged: {
                            // seeked is a workaround for bug 1310706 as the first position after a seek is sometimes invalid (0)
                            if (progressSliderMusic.seeking === false && !progressSliderMusic.seeked) {
                                musicToolbarFullPositionLabel.text = durationToString(player.position)
                                musicToolbarFullDurationLabel.text = durationToString(player.duration)

                                progressSliderMusic.value = player.position
                                progressSliderMusic.maximumValue = player.duration
                            }

                            progressSliderMusic.seeked = false;
                        }
                        onStopped: {
                            musicToolbarFullPositionLabel.text = durationToString(0);
                            musicToolbarFullDurationLabel.text = durationToString(0);
                        }
                    }
                }

                /* Duration label */
                Label {
                    id: musicToolbarFullDurationLabel
                    anchors.top: progressSliderMusic.bottom
                    anchors.topMargin: units.gu(-2)
                    anchors.right: parent.right
                    color: styleMusic.nowPlaying.labelSecondaryColor
                    fontSize: "small"
                    height: parent.height
                    horizontalAlignment: Text.AlignHCenter
                    text: durationToString(player.duration)
                    verticalAlignment: Text.AlignVCenter
                    width: units.gu(3)
                }
            }

            /* Repeat button */
            MouseArea {
                id: nowPlayingRepeatButton
                anchors.right: nowPlayingPreviousButton.left
                anchors.rightMargin: units.gu(1)
                anchors.verticalCenter: nowPlayingPlayButton.verticalCenter
                height: units.gu(6)
                opacity: player.repeat && !emptyPage.noMusic ? 1 : .4
                width: height
                onClicked: player.repeat = !player.repeat

                Icon {
                    id: repeatIcon
                    height: units.gu(3)
                    width: height
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "white"
                    name: "media-playlist-repeat"
                    objectName: "repeatShape"
                    opacity: player.repeat && !emptyPage.noMusic ? 1 : .4
                }
            }

            /* Previous button */
            MouseArea {
                id: nowPlayingPreviousButton
                anchors.right: nowPlayingPlayButton.left
                anchors.rightMargin: units.gu(1)
                anchors.verticalCenter: nowPlayingPlayButton.verticalCenter
                height: units.gu(6)
                opacity: trackQueue.model.count === 0  ? .4 : 1
                width: height
                onClicked: player.previousSong()

                Icon {
                    id: nowPlayingPreviousIndicator
                    height: units.gu(3)
                    width: height
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "white"
                    name: "media-skip-backward"
                    objectName: "previousShape"
                    opacity: 1
                }
            }

            /* Play/Pause button */
            MouseArea {
                id: nowPlayingPlayButton
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: musicToolbarFullProgressContainer.bottom
                anchors.topMargin: units.gu(2)
                height: units.gu(12)
                width: height
                onClicked: player.toggle()

                Icon {
                    id: nowPlayingPlayIndicator
                    height: units.gu(6)
                    width: height
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: emptyPage.noMusic ? .4 : 1
                    color: "white"
                    name: player.playbackState === MediaPlayer.PlayingState ? "media-playback-pause" : "media-playback-start"
                    objectName: "playShape"
                }
            }

            /* Next button */
            MouseArea {
                id: nowPlayingNextButton
                anchors.left: nowPlayingPlayButton.right
                anchors.leftMargin: units.gu(1)
                anchors.verticalCenter: nowPlayingPlayButton.verticalCenter
                height: units.gu(6)
                opacity: trackQueue.model.count === 0 ? .4 : 1
                width: height
                onClicked: player.nextSong()

                Icon {
                    id: nowPlayingNextIndicator
                    height: units.gu(3)
                    width: height
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "white"
                    name: "media-skip-forward"
                    objectName: "forwardShape"
                    opacity: 1
                }
            }

            /* Shuffle button */
            MouseArea {
                id: nowPlayingShuffleButton
                anchors.left: nowPlayingNextButton.right
                anchors.leftMargin: units.gu(1)
                anchors.verticalCenter: nowPlayingPlayButton.verticalCenter
                height: units.gu(6)
                opacity: player.shuffle && !emptyPage.noMusic ? 1 : .4
                width: height
                onClicked: player.shuffle = !player.shuffle

                Icon {
                    id: shuffleIcon
                    height: units.gu(3)
                    width: height
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "white"
                    name: "media-playlist-shuffle"
                    objectName: "shuffleShape"
                    opacity: player.shuffle && !emptyPage.noMusic ? 1 : .4
                }
            }
        }
    }

    Loader {
        id: queueListLoader
        anchors {
            fill: parent
        }
        asynchronous: true
        sourceComponent: ListView {
            id: queueList
            anchors {
                bottomMargin: units.gu(2)
                fill: parent
                topMargin: units.gu(2)
            }
            delegate: queueDelegate
            footer: Item {
                height: mainView.height - (styleMusic.common.expandHeight + queueList.currentHeight) + units.gu(8)
            }
            model: trackQueue.model
            objectName: "nowPlayingqueueList"

            property int normalHeight: units.gu(6)
            property int transitionDuration: 250  // transition length of animations

            onCountChanged: {
                customdebug("Queue: Now has: " + queueList.count + " tracks")
            }

            // Requirements for ListItemWithActions
            property var selectedItems: []

            signal clearSelection()
            signal closeSelection()
            signal selectAll()

            onClearSelection: selectedItems = []
            onCloseSelection: {
                clearSelection()
                state = "normal"
            }
            onSelectAll: {
                var tmp = selectedItems

                for (var i=0; i < model.count; i++) {
                    if (tmp.indexOf(i) === -1) {
                        tmp.push(i)
                    }
                }

                selectedItems = tmp
            }
            onVisibleChanged: {
                if (!visible) {
                    clearSelection(true)
                }
            }

            Component.onCompleted: {
                // FIXME: workaround for qtubuntu not returning values depending on the grid unit definition
                // for Flickable.maximumFlickVelocity and Flickable.flickDeceleration
                var scaleFactor = units.gridUnit / 8;
                maximumFlickVelocity = maximumFlickVelocity * scaleFactor;
                flickDeceleration = flickDeceleration * scaleFactor;
            }

            Component {
                id: queueDelegate
                ListItemWithActions {
                    id: queueListItem
                    color: player.currentIndex === index ? "#2c2c34" : mainView.backgroundColor
                    height: queueList.normalHeight
                    objectName: "nowPlayingListItem" + index
                    state: ""

                    leftSideAction: Remove {
                        onTriggered: trackQueue.removeQueue(index)
                    }
                    multiselectable: true
                    reorderable: true
                    rightSideActions: [
                        AddToPlaylist{

                        }
                    ]

                    onItemClicked: {
                        customdebug("File: " + model.filename) // debugger
                        trackQueueClick(index);  // toggle track state
                    }
                    onReorder: {
                        console.debug("Move: ", from, to);

                        trackQueue.model.move(from, to, 1);
                        Library.moveQueueItem(from, to);

                        // Maintain currentIndex with current song
                        if (from === player.currentIndex) {
                            player.currentIndex = to;
                        }
                        else if (from < player.currentIndex && to >= player.currentIndex) {
                            player.currentIndex -= 1;
                        }
                        else if (from > player.currentIndex && to <= player.currentIndex) {
                            player.currentIndex += 1;
                        }

                        queueIndex = player.currentIndex
                    }

                    Item {
                        id: trackContainer;
                        anchors {
                            fill: parent
                        }

                        NumberAnimation {
                            id: trackContainerReorderAnimation
                            target: trackContainer;
                            property: "anchors.leftMargin";
                            duration: queueList.transitionDuration;
                            to: units.gu(2)
                        }

                        NumberAnimation {
                            id: trackContainerResetAnimation
                            target: trackContainer;
                            property: "anchors.leftMargin";
                            duration: queueList.transitionDuration;
                            to: units.gu(0.5)
                        }

                        MusicRow {
                            id: musicRow
                            height: parent.height
                            column: Column {
                                Label {
                                    id: trackTitle
                                    color: player.currentIndex === index ? UbuntuColors.blue
                                                                            : styleMusic.common.music
                                    fontSize: "small"
                                    objectName: "titleLabel"
                                    text: model.title
                                }

                                Label {
                                    id: trackArtist
                                    color: styleMusic.common.subtitle
                                    fontSize: "x-small"
                                    objectName: "artistLabel"
                                    text: model.author
                                }
                            }
                        }
                    }
                }
            }
        }
        visible: isListView
    }
}
