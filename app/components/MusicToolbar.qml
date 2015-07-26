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
import QtMultimedia 5.0
import Ubuntu.Components 1.2

Rectangle {
    anchors {
        bottom: parent.bottom
        left: parent.left
        right: parent.right
    }
    color: styleMusic.common.black
    height: units.gu(7.25)
    objectName: "musicToolbarObject"

    // Hack for autopilot otherwise MusicToolbar appears as QQuickRectangle
    // due to bug 1341671 it is required that there is a property so that
    // qml doesn't optimise using the parent type
    property bool bug1341671workaround: true

    /* Toolbar controls */
    Item {
        id: toolbarControls
        anchors {
            fill: parent
        }
        state: newPlayer.mediaPlayer.playlist.empty ? "disabled" : "enabled"
        states: [
            State {
                name: "disabled"
                PropertyChanges {
                    target: disabledPlayerControlsGroup
                    visible: true
                }
                PropertyChanges {
                    target: enabledPlayerControlsGroup
                    visible: false
                }
            },
            State {
                name: "enabled"
                PropertyChanges {
                    target: disabledPlayerControlsGroup
                    visible: false
                }
                PropertyChanges {
                    target: enabledPlayerControlsGroup
                    visible: true
                }
            }
        ]

        /* Disabled (empty state) controls */
        Item {
            id: disabledPlayerControlsGroup
            anchors {
                bottom: playerControlsProgressBar.top
                left: parent.left
                right: parent.right
                top: parent.top
            }

            Label {
                id: noSongsInQueueLabel
                anchors {
                    left: parent.left
                    leftMargin: units.gu(2)
                    right: disabledPlayerControlsPlayButton.left
                    rightMargin: units.gu(2)
                    verticalCenter: parent.verticalCenter
                }
                color: styleMusic.playerControls.labelColor
                text: i18n.tr("Tap to shuffle music")
                fontSize: "large"
                visible: !emptyPageLoader.noMusic
                wrapMode: Text.WordWrap
                maximumLineCount: 2
            }

            /* Play/Pause button */
            Icon {
                id: disabledPlayerControlsPlayButton
                anchors {
                    right: parent.right
                    rightMargin: units.gu(3)
                    verticalCenter: parent.verticalCenter
                }
                color: "#FFF"
                height: units.gu(4)
                name: newPlayer.mediaPlayer.playbackState === MediaPlayer.PlayingState ?
                          "media-playback-pause" : "media-playback-start"
                objectName: "disabledSmallPlayShape"
                width: height
            }

            /* Click to shuffle music */
            MouseArea {
                anchors {
                    fill: parent
                }
                onClicked: {
                    if (emptyPageLoader.noMusic) {
                        return;
                    }

                    if (newPlayer.mediaPlayer.playlist.empty) {
                        playRandomSong();
                    } else {
                        newPlayer.mediaPlayer.toggle();
                    }
                }
            }
        }

        /* Enabled (queue > 0) controls */
        Item {
            id: enabledPlayerControlsGroup
            anchors {
                bottom: playerControlsProgressBar.top
                left: parent.left
                right: parent.right
                top: parent.top
            }

            /* Album art in player controls */
            CoverGrid {
                 id:  playerControlsImage
                 anchors {
                     bottom: parent.bottom
                     left: parent.left
                     top: parent.top
                 }
                 covers: [newPlayer.currentMeta]
                 size: parent.height
            }

            /* Column of meta labels */
            Column {
                id: playerControlsLabels
                anchors {
                    left: playerControlsImage.right
                    leftMargin: units.gu(1.5)
                    right: playerControlsPlayButton.left
                    rightMargin: units.gu(1)
                    verticalCenter: parent.verticalCenter
                }

                /* Title of track */
                Label {
                    id: playerControlsTitle
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    color: "#FFF"
                    elide: Text.ElideRight
                    fontSize: "small"
                    font.weight: Font.DemiBold
                    text: newPlayer.currentMeta.title === ""
                          ? newPlayer.mediaPlayer.playlist.currentSource
                          : newPlayer.currentMeta.title
                }

                /* Artist of track */
                Label {
                    id: playerControlsArtist
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    color: "#FFF"
                    elide: Text.ElideRight
                    fontSize: "small"
                    opacity: 0.4
                    text: newPlayer.currentMeta.author
                }
            }

            /* Play/Pause button */
            Icon {
                id: playerControlsPlayButton
                anchors {
                    right: parent.right
                    rightMargin: units.gu(3)
                    verticalCenter: parent.verticalCenter
                }
                color: "#FFF"
                height: units.gu(4)
                name: newPlayer.mediaPlayer.playbackState === MediaPlayer.PlayingState ?
                          "media-playback-pause" : "media-playback-start"
                objectName: "playShape"
                width: height
            }

            /* Mouse area to jump to now playing */
            MouseArea {
                anchors {
                    fill: parent
                }
                objectName: "jumpNowPlaying"

                onClicked: tabs.pushNowPlaying()
            }

            /* Mouse area for the play button (ontop of the jump to now playing) */
            MouseArea {
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: playerControlsPlayButton.horizontalCenter
                    top: parent.top
                }
                onClicked: newPlayer.mediaPlayer.toggle()
                width: units.gu(8)

                Rectangle {
                    anchors {
                        fill: parent
                    }
                    color: "#FFF"
                    opacity: parent.pressed ? 0.1 : 0

                    Behavior on opacity {
                        UbuntuNumberAnimation {
                            duration: UbuntuAnimation.FastDuration
                        }
                    }
                }
            }
        }

        /* Object which provides the progress bar when toolbar is minimized */
        Rectangle {
            id: playerControlsProgressBar
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            color: styleMusic.common.black
            height: units.gu(0.25)

            Rectangle {
                id: playerControlsProgressBarHint
                anchors {
                    left: parent.left
                    top: parent.top
                }
                color: UbuntuColors.blue
                height: parent.height
                width: newPlayer.mediaPlayer.progress * playerControlsProgressBar.width

                /*
                  FIXME: needed?

                Connections {
                    target: newPlayer.mediaPlayer
                    onPositionChanged: playerControlsProgressBarHint.width = (newPlayer.mediaPlayer.position / newPlayer.mediaPlayer.duration) * playerControlsProgressBar.width
                    onStopped: playerControlsProgressBarHint.width = 0;
                }
                */
            }
        }
    }
}
