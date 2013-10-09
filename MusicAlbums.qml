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
import QtGraphicalEffects 1.0
import "settings.js" as Settings
import "meta-database.js" as Library
import "playlists.js" as Playlists
import "common"

Page {
    id: mainpage
    title: i18n.tr("Albums")

    property string artist: ""
    property string album: ""
    property string songtitle: ""
    property string cover: ""
    property string length: ""
    property string file: ""
    property string year: ""

    MusicSettings {
        id: musicSettings
    }

    onVisibleChanged: {
        if (visible === true)
        {
            musicToolbar.setPage(mainpage);
        }
    }

    GridView {
        id: albumlist
        anchors.fill: parent
        anchors.bottomMargin: musicToolbar.mouseAreaOffset + musicToolbar.minimizedHeight
        cellHeight: units.gu(14)
        cellWidth: units.gu(14)
        model: albumModel.model
        delegate: albumDelegate

        Component {
            id: albumDelegate
            Item {
                id: albumItem
                height: units.gu(13)
                width: units.gu(13)
                anchors.margins: units.gu(1)
                UbuntuShape {
                    id: albumShape
                    height: albumItem.width
                    width: albumItem.width
                    image: Image {
                        id: icon
                        fillMode: Image.Stretch
                        property string artist: model.artist
                        property string album: model.album
                        property string title: model.title
                        property string cover: model.cover
                        property string length: model.length
                        property string file: model.file
                        property string year: model.year
                        source: cover !== "" ? cover : "images/cover_default.png"
                    }
                    UbuntuShape {  // Background so can see text in current state
                        id: albumBg
                        anchors.bottom: parent.bottom
                        color: styleMusic.common.black
                        height: units.gu(4)
                        opacity: .75
                        width: parent.width
                    }
                    Label {
                        id: albumLabel
                        anchors.bottom: albumArtist.top
                        horizontalAlignment: Text.AlignHCenter
                        color: styleMusic.nowPlaying.labelSecondaryColor
                        elide: Text.ElideRight
                        text: album
                        fontSize: "small"
                        width: parent.width
                    }
                    Label {
                        id: albumArtist
                        anchors.bottom: parent.bottom
                        horizontalAlignment: Text.AlignHCenter
                        color: styleMusic.nowPlaying.labelSecondaryColor
                        elide: Text.ElideRight
                        text: artist
                        fontSize: "small"
                        width: parent.width
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
                        mainpage.artist = artist
                        mainpage.album = album
                        mainpage.file = file
                        mainpage.year = year
                        mainpage.cover = cover
                        PopupUtils.open(albumSheet)
                    }
                }
            }
        }
    }

    Component {
        id: albumSheet
        DefaultSheet {
            id: sheet
            anchors.bottomMargin: units.gu(.5)
            doneButton: false
            contentsHeight: parent.height
            contentsWidth: parent.width

            // Blurred background
            BlurredBackground {
            }

            ListView {
                clip: true
                id: albumtrackslist
                width: parent.width
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                model: albumTracksModel.model
                delegate: albumTracksDelegate
                header: ListItem.Standard {
                    id: albumInfo
                    width: parent.width
                    height: units.gu(20)

                    UbuntuShape {
                        id: albumImage
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: units.gu(1)
                        height: parent.height
                        width: height
                        image: Image {
                            source: Library.hasCover(mainpage.file) ? mainpage.cover : Qt.resolvedUrl("images/cover_default.png")
                        }
                    }
                    Label {
                        id: albumTitle
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                        fontSize: "large"
                        anchors.left: albumImage.right
                        anchors.leftMargin: units.gu(1)
                        anchors.top: parent.top
                        anchors.topMargin: units.gu(1.5)
                        anchors.right: parent.right
                        text: mainpage.album
                    }
                    Label {
                        id: albumArtist
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                        fontSize: "medium"
                        anchors.left: albumImage.right
                        anchors.leftMargin: units.gu(1)
                        anchors.top: albumTitle.bottom
                        anchors.topMargin: units.gu(1)
                        anchors.right: parent.right
                        text: mainpage.artist
                    }
                    Label {
                        id: albumYear
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                        fontSize: "small"
                        anchors.left: albumImage.right
                        anchors.leftMargin: units.gu(1)
                        anchors.top: albumArtist.bottom
                        anchors.topMargin: units.gu(1)
                        anchors.right: parent.right
                        text: mainpage.year
                    }
                    Label {
                        id: albumCount
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                        fontSize: "small"
                        anchors.left: albumImage.right
                        anchors.leftMargin: units.gu(1)
                        anchors.top: albumYear.bottom
                        anchors.topMargin: units.gu(1)
                        anchors.right: parent.right
                        text: albumTracksModel.model.count + " songs"
                    }

                }

                onCountChanged: {
                    albumtrackslist.currentIndex = albumTracksModel.indexOf(currentFile)
                }

                Component {
                    id: albumTracksDelegate

                    ListItem.Standard {
                        id: track
                        iconFrame: false
                        progression: false
                        height: styleMusic.common.itemHeight
                        Label {
                            id: trackTitle
                            wrapMode: Text.NoWrap
                            maximumLineCount: 1
                            fontSize: "medium"
                            anchors.left: parent.left
                            anchors.leftMargin: units.gu(2)
                            anchors.top: parent.top
                            anchors.topMargin: units.gu(1.5)
                            anchors.right: parent.right
                            text: model.title == "" ? model.file : model.title
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
                                Image {
                                    id: playlistTrack
                                    source: "images/add.svg"
                                    height: styleMusic.common.expandedItem
                                    width: styleMusic.common.expandedItem
                                }
                                Label {
                                    text: i18n.tr("Add to playlist")
                                    wrapMode: Text.WordWrap
                                    fontSize: "small"
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
                                Image {
                                    id: queueTrack
                                    source: "images/queue.png"
                                    height: styleMusic.common.expandedItem
                                    width: styleMusic.common.expandedItem
                                }
                                Label {
                                    text: i18n.tr("Queue")
                                    wrapMode: Text.WordWrap
                                    fontSize: "small"
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
                                visible: false
                                Icon {
                                    id: shareTrack
                                    name: "share"
                                    height: styleMusic.common.expandedItem
                                    width: styleMusic.common.expandedItem
                                }
                                Label {
                                    text: i18n.tr("Share")
                                    wrapMode: Text.WordWrap
                                    fontSize: "small"
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
                                trackClicked(albumTracksModel, index)  // play track
                                // TODO: This closes the SDK defined sheet
                                //       component. It should be able to close
                                //       albumSheet.
                                PopupUtils.close(sheet)
                            }
                        }
                        Component.onCompleted: {
                        }
                    }
                }
            }
        }
    }
}


