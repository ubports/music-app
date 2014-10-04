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
    objectName: "nowPlayingPage"
    title: i18n.tr("Now Playing")
    visible: false
    onVisibleChanged: {
        if (!visible) {
            // Reset the isListView property
            // TODO: In the future this will default to false
            isListView = true
        }
    }

    property int ensureVisibleIndex: 0  // ensure first index is visible at startup
    property bool isListView: true

    Component.onCompleted: {
        if (isListView) {
            onToolbarShownChanged.connect(jumpToCurrent)
        }
    }

    head {
        actions: [
            Action {
                objectName: "toggleView"
                iconName: "media-playlist"
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

            // Always jump to current track
            nowPlaying.jumpToCurrent(musicToolbar.opened, nowPlaying, musicToolbar.currentTab)

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
        visible: !isListView
        anchors.fill: parent
        color: "transparent"
        clip: true

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
                z: 1

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
                    function formatValue(v) { return durationToString(v) }

                    property bool seeking: false

                    onSeekingChanged: {
                        if (seeking === false) {
                            musicToolbarFullPositionLabel.text = durationToString(player.position)
                        }
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
                objectName: "repeatShape"
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
                objectName: "previousShape"
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
                    opacity: 1
                }
            }

            /* Play/Pause button */
            MouseArea {
                id: nowPlayingPlayButton
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top:musicToolbarFullProgressContainer.bottom
                anchors.topMargin: units.gu(2)
                height: units.gu(12)
                objectName: "playShape"
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
                }
            }

            /* Next button */
            MouseArea {
                id: nowPlayingNextButton
                anchors.left: nowPlayingPlayButton.right
                anchors.leftMargin: units.gu(1)
                anchors.verticalCenter: nowPlayingPlayButton.verticalCenter
                height: units.gu(6)
                objectName: "forwardShape"
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
                    opacity: 1
                }
            }

            /* Shuffle button */
            MouseArea {
                id: nowPlayingShuffleButton
                objectName: "shuffleShape"
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
                    opacity: player.shuffle && !emptyPage.noMusic ? 1 : .4
                }
            }
        }
    }

    ListView {
        id: queuelist
        visible: isListView
        objectName: "nowPlayingQueueList"
        anchors.fill: parent
        anchors.bottomMargin: musicToolbar.mouseAreaOffset + musicToolbar.minimizedHeight
        delegate: queueDelegate
        model: trackQueue.model
        highlightFollowsCurrentItem: false
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
        footer: Item {
            height: mainView.height - (styleMusic.common.expandHeight + queuelist.currentHeight) + units.gu(8)
        }

        property int normalHeight: units.gu(12)
        property int currentHeight: units.gu(40)
        property int transitionDuration: 250  // transition length of animations

        onCountChanged: {
            customdebug("Queue: Now has: " + queuelist.count + " tracks")
        }

        onMovementStarted: {
            musicToolbar.hideToolbar();
        }

        Component {
            id: queueDelegate
            ListItemWithActions {
                id: queueListItem
                color: "transparent"
                height: queuelist.normalHeight
                objectName: "nowPlayingListItem" + index
                state: queuelist.currentIndex == index && !reordering ? "current" : ""

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
                        margins: units.gu(1)
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

                    CoverRow {
                        id: trackImage

                        anchors {
                            top: parent.top
                            left: parent.left
                            leftMargin: units.gu(1.5)
                        }
                        count: 1
                        size: (queueListItem.state === "current"
                               ? (mainView.wideAspect
                                  ? queuelist.currentHeight
                                  : mainView.width - (trackImage.anchors.leftMargin * 2))
                               : queuelist.normalHeight) - units.gu(2)
                        covers: [{art: model.art, album: model.album, author: model.author}]

                        spacing: units.gu(2)

                        Item {  // Background so can see text in current state
                            id: albumBg
                            visible: false
                            anchors {
                                bottom: parent.bottom
                                left: parent.left
                                right: parent.right
                            }
                            height: units.gu(9)
                            clip: true
                            UbuntuShape{
                                anchors {
                                    bottom: parent.bottom
                                    left: parent.left
                                    right: parent.right
                                }
                                height: trackImage.height
                                radius: "medium"
                                color: styleMusic.common.black
                                opacity: 0.6
                            }
                        }

                        function calcAnchors() {
                            if (trackImage.height > queuelist.normalHeight && mainView.wideAspect) {
                                trackImage.anchors.left = undefined
                                trackImage.anchors.horizontalCenter = trackImage.parent.horizontalCenter
                            } else {
                                trackImage.anchors.left = trackImage.parent.left
                                trackImage.anchors.horizontalCenter = undefined
                            }

                            trackImage.width = trackImage.height;  // force width to match height
                        }

                        Connections {
                            target: mainView
                            onWideAspectChanged: trackImage.calcAnchors()
                        }

                        onHeightChanged: {
                            calcAnchors()
                        }
                        Behavior on height {
                            NumberAnimation {
                                target: trackImage;
                                property: "height";
                                duration: queuelist.transitionDuration;
                            }
                        }
                    }
                    Label {
                        id: nowPlayingArtist
                        objectName: "artistLabel"
                        color: styleMusic.nowPlaying.labelSecondaryColor
                        elide: Text.ElideRight
                        height: units.gu(1)
                        text: model.author
                        fontSize: 'small'
                        width: parent.width - trackImage.width - units.gu(3.5)
                        x: trackImage.x + trackImage.width + units.gu(1)
                        y: trackImage.y + units.gu(1)
                    }
                    Label {
                        id: nowPlayingTitle
                        objectName: "titleLabel"
                        color: styleMusic.common.white
                        elide: Text.ElideRight
                        height: units.gu(1)
                        text: model.title
                        fontSize: 'medium'
                        width: parent.width - trackImage.width - units.gu(3.5)
                        x: trackImage.x + trackImage.width + units.gu(1)
                        y: nowPlayingArtist.y + nowPlayingArtist.height + units.gu(1.25)
                    }
                    Label {
                        id: nowPlayingAlbum
                        objectName: "albumLabel"
                        color: styleMusic.nowPlaying.labelSecondaryColor
                        elide: Text.ElideRight
                        height: units.gu(1)
                        text: model.album
                        fontSize: 'x-small'
                        width: parent.width - trackImage.width - units.gu(3.5)
                        x: trackImage.x + trackImage.width + units.gu(1)
                        y: nowPlayingTitle.y + nowPlayingTitle.height + units.gu(1.25)
                    }
                }

                states: State {
                    name: "current"
                    PropertyChanges {
                        target: queueListItem
                        height: trackImage.size + (trackContainer.anchors.margins * 2)
                    }
                    PropertyChanges {
                        target: nowPlayingArtist
                        width: trackImage.width - units.gu(4)
                        x: trackImage.x + units.gu(2)
                        y: trackImage.y + trackImage.height - albumBg.height + units.gu(1)
                        color: styleMusic.common.white
                    }
                    PropertyChanges {
                        target: nowPlayingTitle
                        width: trackImage.width - units.gu(4)
                        x: trackImage.x + units.gu(2)
                        y: nowPlayingArtist.y + nowPlayingArtist.height + units.gu(1.25)
                        color: styleMusic.common.white
                        font.weight: Font.DemiBold
                    }
                    PropertyChanges {
                        target: nowPlayingAlbum
                        width: trackImage.width - units.gu(4)
                        x: trackImage.x + units.gu(2)
                        y: nowPlayingTitle.y + nowPlayingTitle.height + units.gu(1.25)
                        color: styleMusic.common.white
                    }
                    PropertyChanges {
                        target: albumBg
                        visible: true
                    }
                }
                transitions: Transition {
                    from: ",current"
                    to: "current,"
                    NumberAnimation {
                        duration: queuelist.transitionDuration
                        properties: "height,opacity,width,x,y"
                    }

                    onRunningChanged: {
                        if (running === false && ensureVisibleIndex != -1)
                        {
                            queuelist.positionViewAtIndex(ensureVisibleIndex, ListView.Beginning);
                            ensureVisibleIndex = -1;
                        }
                    }
                }
            }
        }
    }
}
