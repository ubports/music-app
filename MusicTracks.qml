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
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import "settings.js" as Settings
import "meta-database.js" as Library
import "playlists.js" as Playlists


PageStack {
    id: pageStack
    anchors.fill: parent

    MusicSettings {
        id: musicSettings
    }

    Page {
        id: mainpage

        tools: ToolbarItems {
            // Settings dialog
            ToolbarButton {
                objectName: "settingsaction"
                iconSource: Qt.resolvedUrl("images/settings.png")
                text: i18n.tr("Settings")

                onTriggered: {
                    console.debug('Debug: Show settings from tracks')
                    PopupUtils.open(Qt.resolvedUrl("MusicSettings.qml"), mainView,
                                    {
                                        title: i18n.tr("Settings")
                                    } )
                }
            }
        }

        title: i18n.tr("Music")
        Component.onCompleted: {
            pageStack.push(mainpage)
        }

        ListView {
            id: tracklist
            width: parent.width
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.bottomMargin: units.gu(8)
            highlightFollowsCurrentItem: false
            model: libraryModel.model
            delegate: trackDelegate
            onCountChanged: {
                //customdebug("onCountChanged: " + tracklist.count) // activate later
                tracklist.currentIndex = libraryModel.indexOf(currentFile)
            }

            Component {
                id: trackDelegate
                ListItem.Standard {
                    id: track
                    property string artist: model.artist
                    property string album: model.album
                    property string title: model.title
                    property string cover: model.cover
                    property string length: model.length
                    property string file: model.file
                    width: parent.width
                    height: styleMusic.common.itemHeight

                    UbuntuShape {
                        id: trackCover
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(2)
                        anchors.top: parent.top
                        anchors.topMargin: units.gu(1)
                        width: styleMusic.common.albumSize
                        height: styleMusic.common.albumSize
                        image: Image {
                            source: cover !== "" ? cover : Qt.resolvedUrl("images/cover_default_icon.png")
                        }
                    }
                    Label {
                        id: trackArtist
                        wrapMode: Text.NoWrap
                        maximumLineCount: 2
                        fontSize: "x-small"
                        anchors.left: trackCover.left
                        anchors.leftMargin: units.gu(11)
                        anchors.top: parent.top
                        anchors.topMargin: units.gu(1.5)
                        text: artist == "" ? "" : artist
                    }
                    Label {
                        id: trackTitle
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                        fontSize: "small"
                        color: styleMusic.common.music
                        anchors.left: trackCover.left
                        anchors.leftMargin: units.gu(11)
                        anchors.top: trackArtist.bottom
                        anchors.topMargin: units.gu(1)
                        text: track.title == "" ? track.file : track.title
                    }
                    Label {
                        id: trackAlbum
                        wrapMode: Text.NoWrap
                        maximumLineCount: 2
                        fontSize: "xx-small"
                        anchors.left: trackCover.left
                        anchors.leftMargin: units.gu(11)
                        anchors.top: trackTitle.bottom
                        anchors.topMargin: units.gu(2)
                        text: album
                    }
                    Label {
                        id: trackDuration
                        wrapMode: Text.NoWrap
                        maximumLineCount: 2
                        fontSize: "small"
                        color: styleMusic.common.music
                        anchors.left: trackCover.left
                        anchors.leftMargin: units.gu(12)
                        anchors.top: trackAlbum.bottom
                        visible: false
                        text: ""
                    }
                    onFocusChanged: {
                    }
                    MouseArea {
                        anchors.fill: parent
                        onDoubleClicked: {
                        }
                        onClicked: {
                            if (focus == false) {
                                focus = true
                            }

                            trackClicked(libraryModel, index)  // play track
                            // collapse expanded item on click on track
                            if(expandable.visible) {
                                expandable.visible = false
                                track.height = styleMusic.common.itemHeight
                            }
                        }
                    }
                    Component.onCompleted: {
                        // Set first track as current track
                        if (trackQueue.model.count === 0 && !argFile) {
                            trackClicked(libraryModel, index, false)
                        }

                        console.log("Title:" + title + " Artist: " + artist)
                    }
                    states: State {
                        name: "Current"
                        when: track.ListView.isCurrentItem
                    }
                    Image {
                        id: expandItem
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(2)
                        anchors.top: parent.top
                        anchors.topMargin: units.gu(4)
                        source: "images/select.png"
                        height: styleMusic.common.expandedItem
                        width: styleMusic.common.expandedItem

                        MouseArea {
                           anchors.fill: parent
                           onClicked: {
                               if(expandable.visible) {
                                   customdebug("clicked collapse")
                                   expandable.visible = false
                                   track.height = styleMusic.common.itemHeight

                               }
                               else {
                                   customdebug("clicked expand")
                                   expandable.visible = true
                                   track.height = styleMusic.common.expandedHeight
                               }
                           }
                       }
                    }

                    Rectangle {
                        id: expandable
                        visible: false
                        anchors.top: parent.buttom
                        width: parent.fill
                        height: styleMusic.common.expandHeight
                        color: "black"
                        opacity: 0.7
                        MouseArea {
                           anchors.fill: parent
                           onClicked: {
                               customdebug("User pressed outside the playlist item and expanded items.")
                         }
                       }
                        // add to playlist
                        Row {
                            id: playlistRow
                            anchors.top: parent.top
                            anchors.topMargin: styleMusic.common.expandedTopMargin
                            anchors.left: parent.left
                            anchors.leftMargin: styleMusic.common.expandedLeftMargin
                            height: styleMusic.common.expandedItem
                            width: units.gu(15)
                            UbuntuShape {
                                id: playlistTrack
                                color: get_random_color()
                                height: styleMusic.common.expandedItem
                                width: styleMusic.common.expandedItem
                            }
                            Label {
                                text: i18n.tr("Add to playlist")
                                anchors.left: playlistTrack.right
                                anchors.leftMargin: units.gu(0.5)
                            }
                            MouseArea {
                               anchors.fill: parent
                               onClicked: {
                                   expandable.visible = false
                                   track.height = styleMusic.common.itemHeight
                                   chosenArtist = artist
                                   chosenTitle = title
                                   chosenTrack = file
                                   chosenAlbum = album
                                   chosenCover = cover
                                   chosenGenre = genre
                                   chosenIndex = index
                                   console.debug("Debug: Add track to playlist")
                                   PopupUtils.open(Qt.resolvedUrl("MusicaddtoPlaylist.qml"), mainView,
                                   {
                                       title: i18n.tr("Select playlist")
                                   } )
                             }
                           }
                        }
                        // Queue
                        Row {
                            id: queueRow
                            anchors.top: parent.top
                            anchors.topMargin: styleMusic.common.expandedTopMargin
                            anchors.left: playlistRow.left
                            anchors.leftMargin: units.gu(15)
                            height: styleMusic.common.expandedItem
                            width: units.gu(15)
                            UbuntuShape {
                                id: queueTrack
                                color: get_random_color()
                                height: styleMusic.common.expandedItem
                                width: styleMusic.common.expandedItem
                            }
                            Label {
                                text: i18n.tr("Queue")
                                anchors.left: queueTrack.right
                                anchors.leftMargin: units.gu(0.5)
                            }
                            MouseArea {
                               anchors.fill: parent
                               onClicked: {
                                   expandable.visible = false
                                   track.height = styleMusic.common.itemHeight
                                   console.debug("Debug: Add track to queue: " + title)
                                   trackQueue.model.append({"title": title, "artist": artist, "file": track, "album": album, "cover": cover, "genre": genre})
                             }
                           }
                        }
                        // Share
                        Row {
                            id: shareRow
                            anchors.top: parent.top
                            anchors.topMargin: styleMusic.common.expandedTopMargin
                            anchors.left: queueRow.left
                            anchors.leftMargin: units.gu(15)
                            height: styleMusic.common.expandedItem
                            width: units.gu(15)
                            UbuntuShape {
                                id: shareTrack
                                color: get_random_color()
                                height: styleMusic.common.expandedItem
                                width: styleMusic.common.expandedItem
                            }
                            Label {
                                text: i18n.tr("Share")
                                anchors.left: shareTrack.right
                                anchors.leftMargin: units.gu(0.5)
                            }
                            MouseArea {
                               anchors.fill: parent
                               onClicked: {
                                   expandable.visible = false
                                   track.height = styleMusic.common.itemHeight
                                   customdebug("Share")
                             }
                           }
                        }
                    }
                }
            }
        }
    }
}
