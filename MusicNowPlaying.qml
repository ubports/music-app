/*
 * Copyright (C) 2013, 2014
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
import "settings.js" as Settings
import "playlists.js" as Playlists

MusicPage {
    id: nowPlaying
    flickable: isListView ? queuelist : null  // Ensures that the header is shown in fullview
    objectName: "nowPlayingPage"
    title: isListView ? i18n.tr("Queue") : i18n.tr("Now playing")
    visible: false

    property bool isListView: false

    onIsListViewChanged: {
        if (isListView) {
            positionAt(player.currentIndex);
        }
    }

    function positionAt(index) {
        queuelist.positionViewAtIndex(index, ListView.Center);
    }

    state: isListView && queuelist.state === "multiselectable" ? "selection" : "default"
    states: [
        PageHeadState {
            id: defaultState

            name: "default"
            backAction: Action {
                iconName: "back";
                objectName: "backButton"
                onTriggered: {
                    mainPageStack.pop();

                    while (mainPageStack.depth > 1) {  // jump back to the tab layer if via SongsPage
                        mainPageStack.pop();
                    }
                }
            }
            actions: [
                Action {
                    objectName: "clearQueue"
                    iconName: "delete"
                    visible: isListView
                    onTriggered: {
                        head.backAction.trigger()
                        trackQueue.model.clear()
                    }
                },
                Action {
                    objectName: "toggleView"
                    iconName: "media-playlist"
                    onTriggered: {
                        isListView = !isListView
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
                onTriggered: queuelist.state = "normal"
            }
            actions: [
                Action {
                    text: i18n.tr("Select All")
                    iconName: "select"
                    onTriggered: {
                        if (queuelist.selectedItems.length === queuelist.model.count) {
                            queuelist.clearSelection(false)
                        } else {
                            queuelist.selectAll()
                        }
                    }
                },
                Action {
                    enabled: queuelist.selectedItems.length > 0
                    iconName: "add-to-playlist"
                    text: i18n.tr("Add to playlist")
                    onTriggered: {
                        var items = []

                        for (var i=0; i < queuelist.selectedItems.length; i++) {
                            items.push(makeDict(trackQueue.model.get(queuelist.selectedItems[i])));
                        }

                        chosenElements = items;
                        mainPageStack.push(addtoPlaylist)

                        queuelist.clearSelection(true)
                    }
                },
                Action {
                    enabled: queuelist.selectedItems.length > 0
                    iconName: "delete"
                    text: i18n.tr("Delete")
                    onTriggered: {
                        for (var i=0; i < queuelist.selectedItems.length; i++) {
                            removeQueue(queuelist.selectedItems[i])
                        }

                        queuelist.clearSelection(true)
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

    Rectangle {
        id: fullview
        anchors.fill: parent
        color: "transparent"
        visible: !isListView

        BlurredBackground {
            id: blurredBackground
            anchors.top: parent.top
            anchors.topMargin: mainView.header.height
            height: units.gu(27)
            art: albumImage.source

            Image {
                id: albumImage
                anchors.centerIn: parent
                width: units.gu(18)
                height: width
                smooth: true
                source: player.currentMetaArt === "" ?
                            decodeURIComponent("image://albumart/artist=" +
                                               player.currentMetaArtist +
                                               "&album=" + player.currentMetaAlbum)
                          : player.currentMetaArt
            }
        }

        /* Full toolbar */
        Item {
            id: musicToolbarFullContainer
            anchors.top: blurredBackground.bottom
            anchors.topMargin: units.gu(4)
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
                    objectName: "playercontroltitle"
                    text: trackQueue.model.count === 0 ? "" : player.currentMetaTitle === "" ? player.currentMetaFile : player.currentMetaTitle
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
                anchors.topMargin: units.gu(3)
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
                    objectName: "progressSliderShape"

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

                    Component.onCompleted: {
                        Theme.palette.selected.foreground = UbuntuColors.blue
                    }

                    onPressedChanged: {
                        seeking = pressed
                        if (!pressed) {
                            seeked = true
                            player.seek(value)
                       }
                    }

                    Connections {
                        target: player
                        onDurationChanged: {
                            musicToolbarFullDurationLabel.text = durationToString(player.duration)
                            progressSliderMusic.maximumValue = player.duration
                        }
                        onPositionChanged: {
                            // seeked is a workaround for bug 1310706 as the first position after a seek is sometimes invalid (0)
                            if (progressSliderMusic.seeking === false && !progressSliderMusic.seeked) {
                                progressSliderMusic.value = player.position
                                musicToolbarFullPositionLabel.text = durationToString(player.position)
                                musicToolbarFullDurationLabel.text = durationToString(player.duration)
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

    function removeQueue(index)
    {
        var removedIndex = index

        if (queuelist.count === 1) {
            player.stop()
            musicToolbar.goBack()
        } else if (index === player.currentIndex) {
            player.nextSong(player.isPlaying);
        }

        queuelist.model.remove(index);

        if (removedIndex < player.currentIndex) {
            // update index as the old has been removed
            player.currentIndex -= 1;
        }
    }

    ListView {
        id: queuelist
        anchors {
            fill: parent
            topMargin: units.gu(2)
        }
        delegate: queueDelegate
        footer: Item {
            height: mainView.height - (styleMusic.common.expandHeight + queuelist.currentHeight) + units.gu(8)
        }
        model: trackQueue.model
        objectName: "nowPlayingQueueList"
        visible: isListView

        property int normalHeight: units.gu(6)
        property int transitionDuration: 250  // transition length of animations

        onCountChanged: {
            customdebug("Queue: Now has: " + queuelist.count + " tracks")
        }

        // Requirements for ListItemWithActions
        property var selectedItems: []

        signal clearSelection(bool closeSelection)
        signal selectAll()

        onClearSelection: {
            selectedItems = []

            if (closeSelection || closeSelection === undefined) {
                state = "normal"
            }
        }
        onSelectAll: {
            for (var i=0; i < model.count; i++) {
                if (selectedItems.indexOf(i) === -1) {
                    selectedItems.push(i)
                }
            }
        }
        onVisibleChanged: {
            if (!visible) {
                clearSelection(true)
            }
        }

        Component {
            id: queueDelegate
            ListItemWithActions {
                id: queueListItem
                color: player.currentIndex === index ? "#2c2c34" : "transparent"
                height: queuelist.normalHeight
                objectName: "nowPlayingListItem" + index
                showDivider: false
                state: ""

                leftSideAction: Remove {
                    onTriggered: removeQueue(index)
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

                    queuelist.model.move(from, to, 1);


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
                }

                Rectangle {
                    id: trackContainer;
                    anchors {
                        fill: parent
                    }
                    color: "transparent"

                    NumberAnimation {
                        id: trackContainerReorderAnimation
                        target: trackContainer;
                        property: "anchors.leftMargin";
                        duration: queuelist.transitionDuration;
                        to: units.gu(2)
                    }

                    NumberAnimation {
                        id: trackContainerResetAnimation
                        target: trackContainer;
                        property: "anchors.leftMargin";
                        duration: queuelist.transitionDuration;
                        to: units.gu(0.5)
                    }

                    MusicRow {
                        id: musicRow
                        covers: [{art: model.art, album: model.album, author: model.author}]
                        showCovers: false
                        coverSize: units.gu(6)
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
}
