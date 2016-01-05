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
import Ubuntu.Components 1.3
import Ubuntu.Thumbnailer 0.1
import "../components/Themes/Ambiance"


Item {
    id: fullview
    anchors {
        fill: parent
    }

    BlurredBackground {
        id: blurredBackground
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        art: albumImage.firstSource
        height: parent.height - units.gu(7)

        Item {
            id: albumImageContainer
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
            }
            height: parent.height
            width: parent.width

            CoverGrid {
                id: albumImage
                anchors.centerIn: parent
                covers: [player.currentMeta]
                size: parent.height
            }
        }

        Rectangle {
            id: nowPlayingWideAspectLabelsBackground
            anchors.bottom: parent.bottom
            color: styleMusic.common.black
            height: nowPlayingWideAspectTitle.lineCount === 1 ? units.gu(10) : units.gu(13)
            opacity: 0.8
            width: parent.width
        }

        /* Column for labels in wideAspect */
        Column {
            id: nowPlayingWideAspectLabels
            spacing: units.gu(1)
            anchors {
                left: parent.left
                leftMargin: units.gu(2)
                right: parent.right
                rightMargin: units.gu(2)
                top: nowPlayingWideAspectLabelsBackground.top
                topMargin: nowPlayingWideAspectTitle.lineCount === 1 ? units.gu(2) : units.gu(1.5)
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
                text: {
                    if (player.mediaPlayer.playlist.empty) {
                        ""
                    } else if (player.currentMeta.title === "") {
                        player.mediaPlayer.playlist.currentSource
                    } else {
                        player.currentMeta.title
                    }
                }
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
                text: player.mediaPlayer.playlist.empty ? "" : player.currentMeta.author
            }
        }

        /* Detect cover art swipe */
        MouseArea {
            anchors.fill: parent
            property string direction: "None"
            property real lastX: -1

            onPressed: lastX = mouse.x

            onReleased: {
                var diff = mouse.x - lastX

                if (Math.abs(diff) < units.gu(4)) {
                    return;
                } else if (diff < 0) {
                    player.mediaPlayer.playlist.nextWrapper()
                } else if (diff > 0) {
                    player.mediaPlayer.playlist.previousWrapper()
                }
            }
        }
    }

    /* Background for progress bar component */
    Rectangle {
        id: musicToolbarFullProgressBackground
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            top: blurredBackground.bottom
        }
        color: styleMusic.common.black
    }

    /* Progress bar component */
    Item {
        id: musicToolbarFullProgressContainer
        anchors.left: parent.left
        anchors.leftMargin: units.gu(3)
        anchors.right: parent.right
        anchors.rightMargin: units.gu(3)
        anchors.top: blurredBackground.bottom
        anchors.topMargin: units.gu(1)
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
            text: durationToString(player.mediaPlayer.position)
            verticalAlignment: Text.AlignVCenter
            width: units.gu(3)
        }

        Slider {
            id: progressSliderMusic
            anchors.left: parent.left
            anchors.right: parent.right
            maximumValue: player.mediaPlayer.duration || 1  // fallback to 1 when 0 so that the progress bar works
            objectName: "progressSliderShape"
            style: UbuntuBlueSliderStyle {}
            value: player.mediaPlayer.position  // load value at startup

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
                    musicToolbarFullPositionLabel.text = durationToString(player.mediaPlayer.position)
                }
            }

            onPressedChanged: {
                seeking = pressed

                if (!pressed) {
                    seeked = true
                    player.mediaPlayer.seek(value)

                    musicToolbarFullPositionLabel.text = durationToString(value)
                }
            }

            Connections {
                target: player.mediaPlayer
                onPositionChanged: {
                    // seeked is a workaround for bug 1310706 as the first position after a seek is sometimes invalid (0)
                    if (progressSliderMusic.seeking === false && !progressSliderMusic.seeked) {
                        musicToolbarFullPositionLabel.text = durationToString(player.mediaPlayer.position)
                        musicToolbarFullDurationLabel.text = durationToString(player.mediaPlayer.duration)

                        progressSliderMusic.value = player.mediaPlayer.position
                        // fallback to 1 when 0 so that the progress bar works
                        progressSliderMusic.maximumValue = player.mediaPlayer.duration || 1
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
            text: durationToString(player.mediaPlayer.duration || 1)
            verticalAlignment: Text.AlignVCenter
            width: units.gu(3)
        }

        // FIXME: Workaround for pad.lv/1494031 by querying gst as it does not
        // emit until it changes to the PLAYING state. But by asking for a
        // value we get gst to perform a query and return a result
        // However this has to be done once the source is set, hence the delay
        //
        // NOTE: This does not solve when the currentIndex is removed though
        Timer {
            id: refreshProgressTimer
            interval: 48
            repeat: false
            onTriggered: {
                if (!progressSliderMusic.seeking) {
                    musicToolbarFullPositionLabel.text = durationToString(player.mediaPlayer.position);
                    musicToolbarFullDurationLabel.text = durationToString(player.mediaPlayer.duration || 1);

                    progressSliderMusic.value = player.mediaPlayer.position
                    // fallback to 1 when 0 so that the progress bar works
                    progressSliderMusic.maximumValue = player.mediaPlayer.duration || 1
                }
            }
        }

        Connections {
            target: player.mediaPlayer.playlist
            // Call timer when source or index changes
            // so we call even if there are duplicate sources or source removal
            onCurrentItemSourceChanged: refreshProgressTimer.start()
            onCurrentIndexChanged: refreshProgressTimer.start()
        }
    }
}
