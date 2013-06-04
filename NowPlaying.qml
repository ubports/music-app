/*
 * Copyleft Daniel Holm.
 *
 * Authors:
 *  Daniel Holm <d.holmen@gmail.com>
 *  Victor Thompson <victor.thompson@gmail.com>
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

import QtQuick 2.0
import Ubuntu.Components 0.1

Page {
    id: nowPlaying
    visible: false

    Rectangle {
        anchors.fill: parent
        height: units.gu(10)
        color: "#333333"
        Column {
            anchors.fill: parent
            anchors.bottomMargin: units.gu(10)

            UbuntuShape {
                id: forwardshape_nowplaying
                height: 50
                width: 50
                anchors.bottom: parent.bottom
                anchors.left: playshape_nowplaying.right
                radius: "none"
                image: Image {
                    id: forwardindicator_nowplaying
                    source: "forward.png"
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
            UbuntuShape {
                id: playshape_nowplaying
                height: 50
                width: 50
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                radius: "none"
                image: Image {
                    id: playindicator_nowplaying
                    source: "play.png"
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    opacity: .7
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (player.playbackState === MediaPlayer.PlayingState)  {
                            playindicator.source = "play.png"
                            player.pause()
                        } else {
                            playindicator.source = "pause.png"
                            player.play()
                        }
                        playindicator_nowplaying.source = playindicator.source
                    }
                }
            }
            UbuntuShape {
                id: backshape_nowplaying
                height: 50
                width: 50
                anchors.bottom: parent.bottom
                anchors.right: playshape_nowplaying.left
                radius: "none"
                image: Image {
                    id: upindicator_nowplaying
                    source: "back.png"
                    anchors.right: parent.right
                    anchors.bottom: parent
                    opacity: .7
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        getSong(-1)
                    }
                }
            }

            Image {
                id: iconbottom_nowplaying
                source: ""
                width: 300
                height: 300
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: units.gu(1)
                anchors.leftMargin: units.gu(1)

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        pageStack.pop(nowPlaying)
                    }
                }
            }
            Label {
                id: fileTitleBottom_nowplaying
                width: units.gu(30)
                wrapMode: Text.Wrap
                color: "#FFFFFF"
                maximumLineCount: 1
                font.pixelSize: 24
                anchors.top: iconbottom_nowplaying.bottom
                anchors.topMargin: units.gu(2)
                anchors.left: parent.left
                anchors.leftMargin: units.gu(2)
                text: ""
            }
            Label {
                id: fileArtistAlbumBottom_nowplaying
                width: units.gu(30)
                wrapMode: Text.Wrap
                color: "#FFFFFF"
                maximumLineCount: 1
                font.pixelSize: 16
                anchors.left: parent.left
                anchors.top: fileTitleBottom_nowplaying.bottom
                anchors.leftMargin: units.gu(2)
                text: ""
            }
            Rectangle {
                id: fileDurationProgressContainer_nowplaying
                anchors.top: fileArtistAlbumBottom_nowplaying.bottom
                anchors.left: parent.left
                anchors.topMargin: units.gu(2)
                anchors.leftMargin: units.gu(2)
                width: units.gu(40)
                color: "#333333"

                Rectangle {
                    id: fileDurationProgressBackground_nowplaying
                    anchors.top: parent.top
                    anchors.topMargin: 4
                    height: 1
                    width: units.gu(40)
                    color: "#FFFFFF"
                    visible: false
                }
                Rectangle {
                    id: fileDurationProgress_nowplaying
                    anchors.top: parent.top
                    height: 8
                    width: 0
                    color: "#DD4814"
                }
            }
            Label {
                id: fileDurationBottom_nowplaying
                anchors.top: fileDurationProgressContainer_nowplaying.bottom
                anchors.left: parent.left
                anchors.topMargin: units.gu(2)
                anchors.leftMargin: units.gu(2)
                width: units.gu(30)
                wrapMode: Text.Wrap
                color: "#FFFFFF"
                maximumLineCount: 1
                font.pixelSize: 16
                text: ""
            }
        }
    }
}
