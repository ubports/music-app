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

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1
import Ubuntu.Components.Popups 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import QtQuick.LocalStorage 2.0
import "../meta-database.js" as Library

Item {
    id: sheetItem

    property string artist: ""
    property alias sheet: sheetComponent

    SongsSheet {
        id: albumSheet
    }

    Component {
        id: sheetComponent
        DefaultSheet {
            id: sheet
            anchors.bottomMargin: units.gu(.5)
            doneButton: false
            contentsHeight: units.gu(80)

            onVisibleChanged: {
                if (visible) {
                    musicToolbar.setSheet(sheet)
                }
                else {
                    musicToolbar.removeSheet(sheet)
                }
            }

            ListView {
                clip: true
                id: albumtrackslist
                width: parent.width
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                model: artistAlbumsModel.model
                delegate: albumTracksDelegate
                header: if (albumtrackslist.count > 1) { artistHeaderDelegate } else { null }

                Component {
                    id: artistHeaderDelegate
                    ListItem.Standard {
                        id: artistInfo
                        height: units.gu(22)
                        width: parent.width

                        CoverRow {
                            id: artistImage
                            anchors {
                                left: parent.left
                                margins: units.gu(1)
                                top: parent.top
                            }
                            count: parseInt(Library.getArtistCovers(artist).length)
                            size: units.gu(20)
                            covers: Library.getArtistCovers(artist)
                            spacing: units.gu(2)
                        }

                        Label {
                            id: artistLabel
                            wrapMode: Text.NoWrap
                            maximumLineCount: 1
                            fontSize: "medium"
                            color: styleMusic.common.music
                            anchors.left: artistImage.right
                            anchors.leftMargin: units.gu(1)
                            anchors.top: parent.top
                            anchors.topMargin: units.gu(1.5)
                            anchors.right: parent.right
                            anchors.rightMargin: units.gu(1.5)
                            elide: Text.ElideRight
                            text: artist
                        }

                        Label {
                            id: artistCount
                            wrapMode: Text.NoWrap
                            maximumLineCount: 2
                            fontSize: "small"
                            anchors.left: artistImage.right
                            anchors.leftMargin: units.gu(1)
                            anchors.top: artistLabel.bottom
                            anchors.topMargin: units.gu(0.8)
                            anchors.right: parent.right
                            anchors.rightMargin: units.gu(1.5)
                            elide: Text.ElideRight
                            text: albumtrackslist.count + " albums"
                        }

                        // Play
                        Rectangle {
                            id: playRow
                            anchors.top: artistCount.bottom
                            anchors.topMargin: units.gu(1)
                            anchors.left: artistImage.right
                            anchors.leftMargin: units.gu(1)
                            color: "transparent"
                            height: units.gu(4)
                            width: units.gu(15)
                            Image {
                                id: playTrack
                                anchors.verticalCenter: parent.verticalCenter
                                source: "../images/add-to-playback.png"
                                height: styleMusic.common.expandedItem
                                width: styleMusic.common.expandedItem
                            }
                            Label {
                                anchors.left: playTrack.right
                                anchors.leftMargin: units.gu(0.5)
                                anchors.verticalCenter: parent.verticalCenter
                                fontSize: "small"
                                width: parent.width - playTrack.width - units.gu(1)
                                text: i18n.tr("Play all")
                                wrapMode: Text.WordWrap
                                maximumLineCount: 3
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    albumTracksModel.filterArtistTracks(artist)
                                    trackQueue.model.clear()
                                    addQueueFromModel(albumTracksModel)
                                    trackClicked(trackQueue, 0)  // play track

                                    // TODO: add links to recent

                                    // TODO: This closes the SDK defined sheet
                                    //       component. It should be able to close
                                    //       albumSheet.
                                    PopupUtils.close(sheet)
                                }
                            }
                        }

                        // Queue
                        Rectangle {
                            id: queueAllRow
                            anchors.top: playRow.bottom
                            anchors.topMargin: units.gu(1)
                            anchors.left: artistImage.right
                            anchors.leftMargin: units.gu(1)
                            color: "transparent"
                            height: units.gu(4)
                            width: units.gu(15)
                            Image {
                                id: queueAll
                                objectName: "albumsheet-queue-all"
                                anchors.verticalCenter: parent.verticalCenter
                                source: "../images/add.svg"
                                height: styleMusic.common.expandedItem
                                width: styleMusic.common.expandedItem
                            }
                            Label {
                                anchors.left: queueAll.right
                                anchors.leftMargin: units.gu(0.5)
                                anchors.verticalCenter: parent.verticalCenter
                                fontSize: "small"
                                width: parent.width - queueAll.width - units.gu(1)
                                text: i18n.tr("Add to queue")
                                wrapMode: Text.WordWrap
                                maximumLineCount: 3
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    albumTracksModel.filterArtistTracks(artist)
                                    addQueueFromModel(albumTracksModel)
                                }
                            }
                        }
                    }
                }

                Component {
                    id: albumTracksDelegate


                    ListItem.Standard {
                        id: albumInfo
                        width: parent.width
                        height: units.gu(20)

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
                            covers: [Library.getAlbumCover(model.album)]
                            spacing: units.gu(2)

                            MouseArea {
                                anchors.fill: parent
                                onDoubleClicked: {
                                }
                                onClicked: {
                                    if (focus == false) {
                                        focus = true
                                    }

                                    albumTracksModel.filterAlbumTracks(album)
                                    albumSheet.line1 = artist
                                    albumSheet.line2 = model.album
                                    albumSheet.isAlbum = true
                                    albumSheet.file = file
                                    albumSheet.year = year
                                    albumSheet.covers = [Library.getAlbumCover(model.album) || Qt.resolvedUrl("../images/music-app-cover@30.png")]
                                    PopupUtils.open(albumSheet.sheet)

                                    // TODO: This closes the SDK defined sheet
                                    //       component. It should be able to close
                                    //       albumSheet.
                                    PopupUtils.close(sheet)
                                }
                            }
                        }

                        Label {
                            id: albumArtist
                            objectName: "artistsheet-albumartist"
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
                            text: artist
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
                            text: album
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
                            text: i18n.tr(model.year + " | %1 song", model.year + " | %1 songs", Library.getAlbumTracks(album).length).arg(Library.getAlbumTracks(album).length)
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
                            Image {
                                id: playTrack
                                objectName: "albumsheet-playtrack"
                                anchors.verticalCenter: parent.verticalCenter
                                source: "../images/add-to-playback.png"
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
                                    albumTracksModel.filterAlbumTracks(album)
                                    Library.addRecent(album, artist, Library.getAlbumCover(album), album, "album")
                                    mainView.hasRecent = true
                                    recentModel.filterRecent()
                                    trackQueue.model.clear()
                                    addQueueFromModel(albumTracksModel)
                                    trackClicked(trackQueue, 0)  // play track

                                    // TODO: This closes the SDK defined sheet
                                    //       component. It should be able to close
                                    //       albumSheet.
                                    PopupUtils.close(sheet)
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
                            Image {
                                id: queueTrack
                                objectName: "albumsheet-queuetrack"
                                anchors.verticalCenter: parent.verticalCenter
                                source: "../images/add.svg"
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
                                    albumTracksModel.filterAlbumTracks(album)
                                    addQueueFromModel(albumTracksModel)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

