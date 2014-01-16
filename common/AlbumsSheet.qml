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
            contentsHeight: parent.height
            contentsWidth: parent.width

            ListView {
                clip: true
                id: albumtrackslist
                width: parent.width
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                model: artistAlbumsModel.model
                delegate: albumTracksDelegate

                onCountChanged: {
                    albumtrackslist.currentIndex = albumTracksModel.indexOf(currentFile)
                }

                Component {
                    id: albumTracksDelegate


                    ListItem.Standard {
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
                                source: Library.getAlbumCover(model.album) || Qt.resolvedUrl("../images/cover_default.png")
                            }
                        }
                        Label {
                            id: albumArtist
                            objectName: "albumsheet-albumartist"
                            wrapMode: Text.NoWrap
                            maximumLineCount: 1
                            fontSize: "small"
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
                            anchors.left: albumImage.right
                            anchors.leftMargin: units.gu(1)
                            anchors.top: albumLabel.bottom
                            anchors.topMargin: units.gu(2)
                            anchors.right: parent.right
                            anchors.rightMargin: units.gu(1.5)
                            elide: Text.ElideRight
                            text: i18n.tr(model.year + " | %1 song", model.year + " | %1 songs", Library.getAlbumTracks(album).length).arg(Library.getAlbumTracks(album).length)
                        }
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
                                albumSheet.covers = [Library.getAlbumCover(model.album) || Qt.resolvedUrl("../images/cover_default.png")]
                                PopupUtils.open(albumSheet.sheet)

                                // TODO: This closes the SDK defined sheet
                                //       component. It should be able to close
                                //       albumSheet.
                                PopupUtils.close(sheet)
                            }
                        }
                    }
                }
            }
        }
    }
}

