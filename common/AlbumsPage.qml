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

import QtQuick 2.3
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 1.0
import Ubuntu.Components.ListItems 1.0 as ListItem
import Ubuntu.MediaScanner 0.1
import Ubuntu.Thumbnailer 0.1
import QtQuick.LocalStorage 2.0
import "../meta-database.js" as Library

MusicPage {
    id: albumStackPage
    objectName: "albumsArtistPage"
    visible: false

    property string artist: ""
    property var covers: []

    ListView {
        id: albumtrackslist
        anchors {
            fill: parent
        }
        delegate: albumTracksDelegate
        header: artistHeaderDelegate
        model: AlbumsModel {
            id: artistsModel
            albumArtist: albumStackPage.artist
            store: musicStore
        }
        width: parent.width

        Component {
            id: artistHeaderDelegate
            ListItem.Standard {
                id: artistInfo
                height: units.gu(32)
                Item {
                    id: artistItem
                    anchors {
                        left: parent.left
                        leftMargin: units.gu(1)
                        verticalCenter: parent.verticalCenter
                    }
                    height: parent.height - units.gu(2)
                    width: height
                    CoverRow {
                        id: artistImage
                        anchors {
                            left: parent.left
                            top: parent.top
                        }

                        count: albumtrackslist.count
                        size: parent.height
                        covers: albumStackPage.covers;
                        spacing: units.gu(4)
                    }
                    Item {  // Background so can see text in current state
                        id: albumBg
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                        }
                        height: units.gu(11)
                        clip: true
                        UbuntuShape{
                            anchors {
                                bottom: parent.bottom
                                left: parent.left
                                right: parent.right
                            }
                            height: artistImage.height
                            radius: "medium"
                            color: styleMusic.common.black
                            opacity: 0.6
                        }
                    }
                    Label {
                        id: albumCount
                        anchors {
                            bottom: parent.bottom
                            bottomMargin: units.gu(8)
                            left: parent.left
                            leftMargin: units.gu(1)
                            right: parent.right
                            rightMargin: units.gu(1)
                        }
                        color: styleMusic.common.white
                        elide: Text.ElideRight
                        text: i18n.tr("%1 album", "%1 albums", albumtrackslist.count).arg(albumtrackslist.count)
                        fontSize: "small"
                    }
                    Label {
                        id: artistLabel
                        objectName: "artistLabel"
                        anchors {
                            left: parent.left
                            leftMargin: units.gu(1)
                            bottom: parent.bottom
                            bottomMargin: units.gu(4.5)
                            right: parent.right
                            rightMargin: units.gu(1)
                        }
                        color: styleMusic.common.white
                        elide: Text.ElideRight
                        text: albumStackPage.artist
                        fontSize: "large"
                    }

                    SongsModel {
                        id: songArtistModel
                        albumArtist: albumStackPage.artist
                        store: musicStore
                    }

                    // Play
                    Rectangle {
                        id: playRow
                        anchors {
                            left: parent.left
                            leftMargin: units.gu(1)
                            bottom: parent.bottom
                            //bottomMargin: units.gu(0)
                        }
                        color: "transparent"
                        height: units.gu(4)
                        width: units.gu(10)
                        Icon {
                            id: playTrack
                            anchors.verticalCenter: parent.verticalCenter
                            name: "media-playback-start"
                            color: styleMusic.common.white
                            height: styleMusic.common.expandedItem
                            width: styleMusic.common.expandedItem
                        }
                        Label {
                            anchors {
                                left: playTrack.right
                                leftMargin: units.gu(0.5)
                                verticalCenter: parent.verticalCenter
                            }
                            fontSize: "small"
                            color: styleMusic.common.white
                            width: parent.width - playTrack.width - units.gu(1)
                            text: i18n.tr("Play all")
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                trackClicked(songArtistModel, 0, true)

                                // TODO: add links to recent
                            }
                        }
                    }

                    // Queue
                    Rectangle {
                        id: queueAllRow
                        anchors {
                            left: playRow.right
                            leftMargin: units.gu(1)
                            bottom: parent.bottom
                            //bottomMargin: units.gu(1)
                        }
                        color: "transparent"
                        height: units.gu(4)
                        width: units.gu(15)
                        Icon {
                            id: queueAll
                            objectName: "albumpage-queue-all"
                            anchors.verticalCenter: parent.verticalCenter
                            name: "add"
                            color: styleMusic.common.white
                            height: styleMusic.common.expandedItem
                            width: styleMusic.common.expandedItem
                        }
                        Label {
                            anchors {
                                left: queueAll.right
                                leftMargin: units.gu(0.5)
                                verticalCenter: parent.verticalCenter
                            }
                            fontSize: "small"
                            color: styleMusic.common.white
                            width: parent.width - queueAll.width - units.gu(1)
                            text: i18n.tr("Add to queue")
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                addQueueFromModel(songArtistModel)
                            }
                        }
                    }
                }
            }
        }

        Component {
            id: albumTracksDelegate


            ListItem.Standard {
                id: albumInfo
                objectName: "albumsArtistListItem" + index
                width: parent.width
                height: units.gu(20)

                SongsModel {
                    id: songAlbumArtistModel
                    albumArtist: model.artist
                    album: model.title
                    store: musicStore
                }
                Repeater {
                    id: songAlbumArtistModelRepeater
                    model: songAlbumArtistModel
                    delegate: Text { text: new Date(model.date).toLocaleString(Qt.locale(),'yyyy'); visible: false }
                    property string year: ""
                    onItemAdded: year = item.text
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (focus == false) {
                            focus = true
                        }

                        songsPage.album = model.title;

                        songsPage.line1 = model.artist
                        songsPage.line2 = model.title
                        songsPage.isAlbum = true
                        songsPage.covers = [{author: model.artist, album: model.title}]
                        songsPage.genre = undefined
                        songsPage.title = i18n.tr("Album")

                        mainPageStack.push(songsPage)
                    }

                    // TODO: If http://pad.lv/1354753 is fixed to expose whether the Shape should appear pressed, update this as well.
                    onPressedChanged: albumImage.pressed = pressed
                }

                CoverRow {
                    id: albumImage
                    anchors {
                        top: parent.top
                        left: parent.left
                        margins: units.gu(1)
                        verticalCenter: parent.verticalCenter
                    }
                    count: 1
                    size: parent.height
                    covers: [{art: model.art}]
                    spacing: units.gu(2)
                }

                Label {
                    id: albumArtist
                    wrapMode: Text.NoWrap
                    maximumLineCount: 1
                    fontSize: "small"
                    color: styleMusic.common.subtitle
                    anchors.left: albumImage.right
                    anchors.leftMargin: units.gu(1)
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(1.5)
                    anchors.right: parent.right
                    anchors.rightMargin: units.gu(1.5)
                    elide: Text.ElideRight
                    text: model.artist
                }
                Label {
                    id: albumLabel
                    wrapMode: Text.NoWrap
                    maximumLineCount: 2
                    fontSize: "medium"
                    color: styleMusic.common.music
                    anchors.left: albumImage.right
                    anchors.leftMargin: units.gu(1)
                    anchors.top: albumArtist.bottom
                    anchors.topMargin: units.gu(0.8)
                    anchors.right: parent.right
                    anchors.rightMargin: units.gu(1.5)
                    elide: Text.ElideRight
                    text: model.title
                }
                Label {
                    id: albumYear
                    wrapMode: Text.NoWrap
                    maximumLineCount: 1
                    fontSize: "x-small"
                    color: styleMusic.common.subtitle
                    anchors.left: albumImage.right
                    anchors.leftMargin: units.gu(1)
                    anchors.top: albumLabel.bottom
                    anchors.topMargin: units.gu(2)
                    anchors.right: parent.right
                    anchors.rightMargin: units.gu(1.5)
                    elide: Text.ElideRight
                    text: songAlbumArtistModelRepeater.year + " | " +
                          i18n.tr("%1 song", "%1 songs",
                                  songAlbumArtistModelRepeater.count).arg(songAlbumArtistModelRepeater.count)
                }

                // Play
                Rectangle {
                    id: playRow
                    anchors.top: albumYear.bottom
                    anchors.topMargin: units.gu(1)
                    anchors.left: albumImage.right
                    anchors.leftMargin: units.gu(1)
                    color: "transparent"
                    height: units.gu(3)
                    width: units.gu(15)
                    Icon {
                        id: playTrack
                        objectName: "albumpage-playtrack"
                        anchors.verticalCenter: parent.verticalCenter
                        name: "media-playback-start"
                        height: styleMusic.common.expandedItem
                        width: styleMusic.common.expandedItem
                    }
                    Label {
                        anchors.left: playTrack.right
                        anchors.leftMargin: units.gu(0.5)
                        anchors.verticalCenter: parent.verticalCenter
                        fontSize: "small"
                        color: styleMusic.common.subtitle
                        width: parent.width - playTrack.width - units.gu(1)
                        text: i18n.tr("Play all")
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Library.addRecent(model.title, artist, "", model.title, "album")
                            mainView.hasRecent = true
                            recentModel.filterRecent()
                            trackClicked(songAlbumArtistModel, 0, true)
                        }
                    }
                }

                // Queue
                Rectangle {
                    id: queueRow
                    anchors.top: playRow.bottom
                    anchors.topMargin: units.gu(1)
                    anchors.left: albumImage.right
                    anchors.leftMargin: units.gu(1)
                    color: "transparent"
                    height: units.gu(3)
                    width: units.gu(15)
                    Icon {
                        id: queueTrack
                        objectName: "albumpage-queuetrack"
                        anchors.verticalCenter: parent.verticalCenter
                        name: "add"
                        height: styleMusic.common.expandedItem
                        width: styleMusic.common.expandedItem
                    }
                    Label {
                        anchors.left: queueTrack.right
                        anchors.leftMargin: units.gu(0.5)
                        anchors.verticalCenter: parent.verticalCenter
                        fontSize: "small"
                        color: styleMusic.common.subtitle
                        width: parent.width - queueTrack.width - units.gu(1)
                        text: i18n.tr("Add to queue")
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            addQueueFromModel(songAlbumArtistModel)
                        }
                    }
                }
            }
        }
    }
}

