/*
 * Copyright (C) 2013 Victor Thompson <victor.thompson@gmail.com>
 *                    Daniel Holm <d.holmen@gmail.com>
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
import Ubuntu.Components.ListItems 0.1
import Ubuntu.Components.Popups 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import org.nemomobile.folderlistmodel 1.0
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import "settings.js" as Settings
import "meta-database.js" as Library
import "playing-list.js" as PlayingList

PageStack {
    id: pageStack
    anchors.fill: parent

    Page {
        id: mainpage
        title: i18n.tr("Albums")
        Component.onCompleted: {
            pageStack.push(mainpage)
        }

        tools: ToolbarItems {
            // Settings dialog
            ToolbarButton {
                objectName: "settingsaction"
                iconSource: Qt.resolvedUrl("images/settings.png")
                text: i18n.tr("Settings")

                onTriggered: {
                    console.debug('Debug: Show settings')
                    PopupUtils.open(Qt.resolvedUrl("MusicSettings.qml"), mainView,
                                    {
                                        title: i18n.tr("Settings")
                                    } )
                }
            }
        }

        Component {
            id: highlight
            Rectangle {
                width: units.gu(.75)
                height: highlight.height
                color: "#FFFFFF";
                Behavior on y {
                    SpringAnimation {
                        spring: 3
                        damping: 0.2
                    }
                }
            }
        }

        GridView {
            id: albumlist
            width: parent.width
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            cellHeight: units.gu(7)
            cellWidth: units.gu(7)
            model: albumModel.model
            delegate: albumDelegate

            Component {
                id: albumDelegate
                Item {
                    height: units.gu(6)
                    width: units.gu(6)
                    anchors.margins: 10
                    UbuntuShape {
                        height: parent.height
                        width: parent.width
                        image: Image {
                            id: icon
                            fillMode: Image.Stretch
                            property string artist: model.artist
                            property string album: model.album
                            property string title: model.title
                            property string cover: model.cover
                            property string length: model.length
                            property string file: model.file
                            source: cover === "" ? Qt.resolvedUrl("images/cover_default_icon.png") : "image://cover-art/"+file
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onDoubleClicked: {
                        }
                        onPressAndHold: {
                        }
                        onClicked: {
                            albumTracksModel.filterAlbumTracks(album)
                            pageStack.push(albumpage)
                        }
                    }
                }
            }
        }
    }

    Page {
        id: albumpage
        title: i18n.tr("Tracks")

        ListView {
            id: albumtrackslist
            clip: true
            width: parent.width
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.bottomMargin: units.gu(8)
            highlight: highlight
            highlightFollowsCurrentItem: true
            model: albumTracksModel.model
            delegate: albumTracksDelegate

            Component {
                id: albumTracksDelegate

                ListItem.Standard {
                    id: track
                    property string artist: model.artist
                    property string album: model.album
                    property string title: model.title
                    property string cover: model.cover
                    property string length: model.length
                    property string file: model.file
                    icon: cover === "" ? (file.match("\\.mp3") ? Qt.resolvedUrl("images/audio-x-mpeg.png") : Qt.resolvedUrl("images/audio-x-vorbis+ogg.png")) : "image://cover-art/"+file
                    iconFrame: false
                    progression: false
                    Label {
                        id: trackTitle
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                        fontSize: "medium"
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(8)
                        anchors.top: parent.top
                        anchors.topMargin: 5
                        anchors.right: parent.right
                        text: track.title == "" ? track.file : track.title
                    }
                    Label {
                        id: trackArtistAlbum
                        wrapMode: Text.NoWrap
                        maximumLineCount: 2
                        fontSize: "small"
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(8)
                        anchors.top: trackTitle.bottom
                        anchors.right: parent.right
                        text: artist == "" ? "" : artist + " - " + album
                    }

                    onFocusChanged: {
                    }
                    MouseArea {
                        anchors.fill: parent
                        onDoubleClicked: {
                        }
                        onPressAndHold: {
                            PopupUtils.open(trackPopoverComponent, mainView)
                            chosenArtist = artist
                            chosenTitle = title
                            chosenTrack = file
                        }
                        onClicked: {
                            if (focus == false) {
                                focus = true
                            }

                            trackClicked(file, index, albumTracksModel.model, albumtrackslist)
                        }
                    }
                    Component.onCompleted: {
                    }
                }
            }
        }
    }
}
