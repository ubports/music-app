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

MusicPage {
    id: nowPlaying
    flickable: isListView ? queuelist : null  // Ensures that the header is shown in fullview
    objectName: "nowPlayingPage"
    title: i18n.tr("Now Playing")
    visible: false
    onVisibleChanged: {
        if (!visible) {
            // Reset the isListView property
            isListView = false
        }
    }

    property int ensureVisibleIndex: 0  // ensure first index is visible at startup
    property bool isListView: false

    head.backAction: Action {
        iconName: "back";
        objectName: "backButton"
        onTriggered: {
            mainPageStack.pop();

            while (mainPageStack.depth > 1) {  // jump back to the tab layer if via SongsPage
                mainPageStack.pop();
            }
        }
    }

    head {
        actions: [
            Action {
                objectName: "toggleView"
                iconName: isListView ? "clear" : "media-playlist"
                onTriggered: {
                    isListView = !isListView
                }
            }
        ]
    }

    Connections {
        target: player
        onCurrentIndexChanged: {
            if (player.source === "") {
                return;
            }

            queuelist.currentIndex = player.currentIndex;

            customdebug("MusicQueue update currentIndex: " + player.source);

            // TODO: Never jump to track? Or only jump to track in queue view?
            if (isListView) {
                nowPlaying.jumpToCurrent(musicToolbar.opened, nowPlaying, musicToolbar.currentTab)
            }
        }
    }

    function jumpToCurrent(shown, currentPage, currentTab)
    {
        // If the toolbar is shown, the page is now playing and snaptrack is enabled
        if (shown && currentPage === nowPlaying && Settings.getSetting("snaptrack") === "1")
        {
            // Then position the view at the current index
            queuelist.positionViewAtIndex(queuelist.currentIndex, ListView.Beginning);
        }
    }

    function positionAt(index) {
        queuelist.positionViewAtIndex(index, ListView.Beginning);
    }

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
                    function formatValue(v) { return durationToString(v) }

                    property bool seeking: false

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
                            if (progressSliderMusic.seeking === false) {
                                progressSliderMusic.value = player.position
                                musicToolbarFullPositionLabel.text = durationToString(player.position)
                                musicToolbarFullDurationLabel.text = durationToString(player.duration)
                            }
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

    ListView {
        id: queuelist
        anchors {
            fill: parent
        }
        delegate: queueDelegate
        footer: Item {
            height: mainView.height - (styleMusic.common.expandHeight + queuelist.currentHeight) + units.gu(8)
        }
        model: trackQueue.model
        highlightFollowsCurrentItem: true
        highlightMoveDuration: 0
        highlight: Rectangle {
            color: "#2c2c34"
            focus: true
        }

        objectName: "nowPlayingQueueList"
        state: "normal"
        states: [
            State {
                name: "normal"
                PropertyChanges {
                    target: queuelist
                    interactive: true
                }
            },
            State {
                name: "reorder"
                PropertyChanges {
                    target: queuelist
                    interactive: false
                }
            }
        ]
        visible: isListView

        property int normalHeight: units.gu(6)
        property int transitionDuration: 250  // transition length of animations

        onCountChanged: {
            customdebug("Queue: Now has: " + queuelist.count + " tracks")
        }

        Component {
            id: queueDelegate
            ListItemWithActions {
                id: queueListItem
                color: "transparent"
                height: queuelist.normalHeight
                objectName: "nowPlayingListItem" + index
                showDivider: false
                state: ""

                leftSideAction: Remove {
                    onTriggered: {
                        if (queuelist.count === 1) {
                            player.stop()
                            musicToolbar.goBack()
                        } else if (index === player.currentIndex) {
                            player.nextSong(player.isPlaying);
                        }

                        if (index < player.currentIndex) {
                            // update index as the old has been removed
                            player.currentIndex -= 1;
                        }

                        queuelist.model.remove(index);
                    }
                }
                reorderable: true
                rightSideActions: [
                    AddToPlaylist{

                    }
                ]
                triggerActionOnMouseRelease: true

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

                // TODO: If http://pad.lv/1354753 is fixed to expose whether the Shape should appear pressed, update this as well.
                onPressedChanged: trackImage.pressed = pressed

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
                                color: queuelist.currentIndex === index ? UbuntuColors.blue
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
