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

import QtQuick 2.3
import QtQuick.LocalStorage 2.0
import QtMultimedia 5.0
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 1.0

Item {
    anchors {
        bottom: parent.bottom
        left: parent.left
        right: parent.right
    }

    // Properties storing the current page info
    property var currentPage: null
    property var currentTab: null

    // Properties and signals for the toolbar
    property alias currentHeight: musicToolbarPanel.height
    property alias opened: musicToolbarPanel.opened

    property bool popping: false

    /* Helper functions */

    // Back button has been pressed, jump up pageStack or back to parent page
    function goBack()
    {
        if (mainPageStack !== null && mainPageStack.depth > 1) {
            mainPageStack.pop(currentPage)
        }
    }

    // Pop a specific page in the stack
    function popPage(page)
    {
        var tmpPages = []

        popping = true

        while (mainPageStack.currentPage !== page && mainPageStack.depth > 0) {
            tmpPages.push(mainPageStack.currentPage)
            mainPageStack.pop()
        }

        if (mainPageStack.depth > 0) {
            mainPageStack.pop()
        }

        for (var i=tmpPages.length - 1; i > -1; i--) {
            mainPageStack.push(tmpPages[i])
        }

        popping = false
    }

    // Set the current page, and any parent/stacks
    function setPage(childPage)
    {
        if (!popping) {
            currentPage = childPage;
        }
    }

    Panel {
        id: musicToolbarPanel
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: units.gu(7.25)
        locked: true
        opened: true

        /* Expanded toolbar */
        Item {
            id: musicToolbarExpandedContainer
            anchors {
                fill: parent
            }

            Rectangle {
                id: musicToolbarPlayerControls
                anchors {
                    fill: parent
                }
                color: "#000"
                state: trackQueue.model.count === 0 ? "disabled" : "enabled"
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
                        visible: !emptyPage.noMusic
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
                        height: units.gu(2.5)
                        name: player.playbackState === MediaPlayer.PlayingState ?
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
                            if (emptyPage.noMusic) {
                                return;
                            }

                            if (trackQueue.model.count === 0) {
                                playRandomSong();
                            }
                            else {
                                player.toggle();
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
                         covers: [{art: player.currentMetaArt, author: player.currentMetaArtist, album: player.currentMetaArt}]
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
                            text: player.currentMetaTitle === ""
                                  ? player.source : player.currentMetaTitle
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
                            text: player.currentMetaArtist
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
                        height: units.gu(2.5)
                        name: player.playbackState === MediaPlayer.PlayingState ?
                                  "media-playback-pause" : "media-playback-start"
                        objectName: "playShape"
                        width: height
                    }

                    MouseArea {
                        anchors {
                            bottom: parent.bottom
                            horizontalCenter: playerControlsPlayButton.horizontalCenter
                            top: parent.top
                        }
                        onClicked: player.toggle()
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

                    /* Mouse area to jump to now playing */
                    Item {
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: playerControlsLabels.right
                            top: parent.top
                        }
                        objectName: "jumpNowPlaying"
                        function trigger() {
                            tabs.pushNowPlaying();
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
                        width: player.duration > 0 ? (player.position / player.duration) * playerControlsProgressBar.width : 0

                        Connections {
                            target: player
                            onPositionChanged: {
                                playerControlsProgressBarHint.width = (player.position / player.duration) * playerControlsProgressBar.width
                            }
                            onStopped: {
                                playerControlsProgressBarHint.width = 0;
                            }
                        }
                    }
                }
            }
        }
    }
}

