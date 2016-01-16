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

import QtMultimedia 5.6
import QtQuick 2.4
import Ubuntu.Components 1.3


/* Full toolbar */
Rectangle {
    id: musicToolbarFullContainer
    anchors {
        fill: parent
    }
    color: styleMusic.common.black

    /* Repeat button */
    MouseArea {
        id: nowPlayingRepeatButton
        anchors.right: nowPlayingPreviousButton.left
        anchors.rightMargin: units.gu(1)
        anchors.verticalCenter: nowPlayingPlayButton.verticalCenter
        height: units.gu(6)
        width: height
        onClicked: player.repeat = !player.repeat

        Icon {
            id: repeatIcon
            height: units.gu(3)
            width: height
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            color: parent.pressed ? UbuntuColors.blue : "white"
            name: "media-playlist-repeat"
            objectName: "repeatShape"
            opacity: player.repeat ? 1 : .2
        }
    }

    /* Previous button */
    MouseArea {
        id: nowPlayingPreviousButton
        enabled: player.mediaPlayer.playlist.canGoPrevious
        anchors.right: nowPlayingPlayButton.left
        anchors.rightMargin: units.gu(1)
        anchors.verticalCenter: nowPlayingPlayButton.verticalCenter
        height: units.gu(6)
        width: height
        onClicked: player.mediaPlayer.playlist.previousWrapper()

        Icon {
            id: nowPlayingPreviousIndicator
            height: units.gu(3)
            width: height
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            color: parent.pressed ? UbuntuColors.blue : "white"
            name: "media-skip-backward"
            objectName: "previousShape"
            opacity: parent.enabled ? 1 : .2
        }
    }

    /* Play/Pause button */
    MouseArea {
        id: nowPlayingPlayButton
        anchors.centerIn: parent
        height: units.gu(10)
        width: height
        onClicked: player.mediaPlayer.toggle()

        Icon {
            id: nowPlayingPlayIndicator
            height: units.gu(6)
            width: height
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            color: parent.pressed ? UbuntuColors.blue : "white"
            name: player.mediaPlayer.playbackState === MediaPlayer.PlayingState ? "media-playback-pause" : "media-playback-start"
            objectName: "playShape"
        }
    }

    /* Next button */
    MouseArea {
        id: nowPlayingNextButton
        anchors.left: nowPlayingPlayButton.right
        anchors.leftMargin: units.gu(1)
        anchors.verticalCenter: nowPlayingPlayButton.verticalCenter
        enabled: player.mediaPlayer.playlist.canGoNext
        height: units.gu(6)
        width: height
        onClicked: player.mediaPlayer.playlist.nextWrapper()

        Icon {
            id: nowPlayingNextIndicator
            height: units.gu(3)
            width: height
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            color: parent.pressed ? UbuntuColors.blue : "white"
            name: "media-skip-forward"
            objectName: "forwardShape"
            opacity: parent.enabled ? 1 : .2
        }
    }

    /* Shuffle button */
    MouseArea {
        id: nowPlayingShuffleButton
        anchors.left: nowPlayingNextButton.right
        anchors.leftMargin: units.gu(1)
        anchors.verticalCenter: nowPlayingPlayButton.verticalCenter
        height: units.gu(6)
        width: height
        onClicked: player.shuffle = !player.shuffle

        Icon {
            id: shuffleIcon
            height: units.gu(3)
            width: height
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            color: parent.pressed ? UbuntuColors.blue : "white"
            name: "media-playlist-shuffle"
            objectName: "shuffleShape"
            opacity: player.shuffle ? 1 : .2
        }
    }

    /* Object which provides the progress bar when in the queue */
    Rectangle {
        id: playerControlsProgressBar
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        color: styleMusic.common.black
        height: units.gu(0.25)
        visible: isListView

        Rectangle {
            id: playerControlsProgressBarHint
            anchors {
                left: parent.left
                bottom: parent.bottom
            }
            color: UbuntuColors.blue
            height: parent.height
            width: player.mediaPlayer.progress * playerControlsProgressBar.width
        }
    }
}
