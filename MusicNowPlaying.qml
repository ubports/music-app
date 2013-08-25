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


import QtMultimedia 5.0
import QtQuick 2.0
import QtQuick.LocalStorage 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import "meta-database.js" as Library

Page {
    id: nowPlaying
    anchors.fill: parent
    visible: false
    onVisibleChanged: {
        if (visible === true)
        {
            header.opacity = 0;
            header.visible = false;
        }
        else
        {
            header.opacity = 1;
            header.visible = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: styleMusic.nowPlaying.backgroundColor
        MouseArea {  // Block events to lower layers
            anchors.fill: parent
        }
    }

    Component.onCompleted: {
        onPlayingTrackChange.connect(updateCurrentIndex)
    }

    function updateCurrentIndex(file)
    {
        customdebug("MusicQueue update currentIndex: " + file)
        queuelist.currentIndex = trackQueue.indexOf(file)
    }

    ListView {
        id: queuelist
        anchors.bottom: fileDurationProgressContainer_nowplaying.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        delegate: queueDelegate
        model: trackQueue.model
        onCountChanged: {
            customdebug("Queue: Now has: " + queuelist.count + " tracks")
        }

        Component {
            id: queueDelegate
            ListItem.Base {
                id: playlistTracks
                state: queuelist.currentIndex == index ? "current" : ""
                onFocusChanged: {
                    if (focus == false) {
                        selected = false
                    } else {
                        selected = false
                    }
                }
                Rectangle {
                    id: trackContainer;
                    anchors.fill: parent
                    color: "transparent"
                    UbuntuShape {
                        id: trackImage
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height
                        width: height
                        image: Image {
                            source: Library.hasCover(file) ? "image://cover-art-full/"+file : Qt.resolvedUrl("images/cover_default.png")
                        }
                        UbuntuShape {  // Background so can see text in current state
                            id: trackBg
                            anchors.top: parent.top
                            color: styleMusic.common.black
                            height: units.gu(6)
                            opacity: 0
                            width: parent.width
                        }
                    }
                    Label {
                        id: nowPlayingTitle
                        anchors.top: parent.top
                        anchors.topMargin: units.gu(0.5)
                        color: styleMusic.common.white
                        height: units.gu(1)
                        text: title
                        x: trackImage.x + trackImage.width + units.gu(1)
                    }
                    Label {
                        id: nowPlayingAlbumArtist
                        anchors.top: nowPlayingTitle.bottom
                        anchors.topMargin: units.gu(1)
                        color: "#AAA"  /* TODO: colour in styleMusic.qml? */
                        text: artist + " - " + album
                        x: trackImage.x + trackImage.width + units.gu(1)
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onDoubleClicked: {
                    }
                    onPressAndHold: {
                        customdebug("Pressed and held queued track "+file)
                    }
                    onClicked: {
                        customdebug("File: " + file) // debugger
                        trackClicked(trackQueue, index) // play track
                    }
                }
                states: State {
                    name: "current"
                    PropertyChanges {
                        target: playlistTracks
                        height: units.gu(40)
                    }
                    PropertyChanges {
                        target: nowPlayingTitle
                        x: trackImage.x + units.gu(1)
                    }
                    PropertyChanges {
                        target: nowPlayingAlbumArtist
                        x: trackImage.x + units.gu(1)
                    }
                    PropertyChanges {
                        target: trackBg
                        opacity: 0.75
                    }
                }
                transitions: Transition {
                    from: ",current"
                    to: "current,"
                    ParallelAnimation {
                        UbuntuNumberAnimation {
                            duration: 250
                            properties: "height,opacity,width,x"
                        }
                    }
                }
            }
        }
    }
    Rectangle {
        /* will be in toolbar eventually */
        id: fileDurationProgressContainer_nowplaying
        anchors.bottom: nowPlayingControls.top
        color: styleMusic.nowPlaying.backgroundColor;
        height: units.gu(1.5);
        width: parent.width;

        // Connection from positionChanged signal
        function updatePosition(position, duration)
        {
            if (player.seeking == false)
            {
                fileDurationProgressContainer_nowplaying.drawProgress(position / duration)
            }
        }

        // Function that sets the progress bar value
        function drawProgress(fraction)
        {
            fileDurationProgress_nowplaying.x = (fraction * fileDurationProgressContainer_nowplaying.width) - fileDurationProgress_nowplaying.width / 2;
        }

        // Function that sets the slider position from the x position of the mouse
        function setSliderPosition(xPosition) {
            var fraction = xPosition / fileDurationProgressContainer_nowplaying.width;

            // Make sure fraction is within limits
            if (fraction > 1.0)
            {
                fraction = 1.0;
            }
            else if (fraction < 0.0)
            {
                fraction = 0.0;
            }

            // Update progress bar and position text
            fileDurationProgressContainer_nowplaying.drawProgress(fraction);
            player.positionStr = __durationToString(fraction * player.duration);
        }

        Component.onCompleted: {
            // Connect to signal from MediaPlayer
            player.positionChange.connect(updatePosition)
        }

        // Black background behind the progress bar
        Rectangle {
            id: fileDurationProgressBackground_nowplaying
            anchors.verticalCenter: parent.verticalCenter;
            color: styleMusic.nowPlaying.progressBackgroundColor;
            height: parent.height;
            width: parent.width;
        }

        // The orange fill of the progress bar
        Rectangle {
            id: fileDurationProgressArea_nowplaying
            anchors.verticalCenter: parent.verticalCenter;
            color: styleMusic.nowPlaying.progressForegroundColor;
            height: parent.height;
            width: fileDurationProgress_nowplaying.x + (height / 2);  // +radius
        }

        // The current position (handle) of the progress bar
        Rectangle {
            id: fileDurationProgress_nowplaying
            anchors.verticalCenter: fileDurationProgressBackground_nowplaying.verticalCenter;
            antialiasing: true
            color: styleMusic.nowPlaying.progressHandleColor
            height: parent.height;
            radius: height / 2
            width: height;

            transitions: Transition {
                NumberAnimation {
                    properties: "x"
                    duration: 1000
                }
            }
        }

        // Mouse events for the progress bar
        MouseArea {
            anchors.fill: parent
            onMouseXChanged: {
                fileDurationProgressContainer_nowplaying.setSliderPosition(mouseX)
            }
            onPressed: {
                player.seeking = true;
                queuelist.interactive = false;  // disable queuelist as it catches onReleased()
            }
            onClicked: {
                fileDurationProgressContainer_nowplaying.setSliderPosition(mouseX)
            }
            onReleased: {
                queuelist.interactive = true;  // reenable queuelist
                player.seek((mouseX / fileDurationProgressContainer_nowplaying.width) * player.duration);
                player.seeking = false;
            }
        }
    }
    Rectangle {
        /* will be in toolbar eventually */
        id: nowPlayingControls
        anchors.bottom: parent.bottom
        color: styleMusic.nowPlaying.backgroundColor
        height: units.gu(10)
        width: parent.width
        UbuntuShape {  /* TODO: remove when toolbar is implemented */
            id: nowPlayingBackButton
            anchors.left: parent.left
            anchors.leftMargin: units.gu(1)
            anchors.verticalCenter: parent.verticalCenter
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                text: i18n.tr("Back")
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    nowPlaying.visible = false
                }
            }
        }
        UbuntuShape {
            id: backshape_nowplaying
            height: parent.height - units.gu(3)
            width: height
            anchors.right: playshape_nowplaying.left
            anchors.rightMargin: units.gu(2)
            anchors.verticalCenter: parent.verticalCenter
            radius: "none"
            image: Image {
                id: backindicator_nowplaying
                source: "images/back.png"
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                opacity: .7
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    previousSong()
                }
            }
        }
        UbuntuShape {
            id: playshape_nowplaying
            height: parent.height - units.gu(3)
            width: height
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            radius: "none"
            image: Image {
                id: playindicator_nowplaying
                source: player.playbackState === MediaPlayer.PlayingState ?
                          "images/pause.png" : "images/play.png"
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                opacity: .7
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (player.playbackState === MediaPlayer.PlayingState)  {
                        player.pause()
                    } else {
                        player.play()
                    }
                }
            }
        }
        UbuntuShape {
            id: forwardshape_nowplaying
            height: parent.height - units.gu(3)
            width: height
            anchors.left: playshape_nowplaying.right
            anchors.leftMargin: units.gu(2)
            anchors.verticalCenter: parent.verticalCenter
            radius: "none"
            image: Image {
                id: forwardindicator_nowplaying
                source: "images/forward.png"
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                opacity: .7
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    nextSong()
                }
            }
        }
        UbuntuShape {  /* TODO: remove when toolbar is implemented */
            id: nowPlayingClearQueue
            anchors.right: parent.right
            anchors.rightMargin: units.gu(1)
            anchors.verticalCenter: parent.verticalCenter
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                text: i18n.tr("Clear")
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    console.debug("Debug: Track queue cleared.")
                    trackQueue.model.clear()
                }
            }
        }
    }
}
