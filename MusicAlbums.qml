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
import Ubuntu.MediaScanner 0.1
import Ubuntu.Thumbnailer 0.1
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import QtGraphicalEffects 1.0
import "settings.js" as Settings
import "playlists.js" as Playlists
import "common"

MusicPage {
    id: mainpage
    objectName: "albumsPage"
    title: i18n.tr("Albums")

    // TODO: This ListView is empty and causes the header to get painted with the desired background color because the
    //       page is now vertically flickable.
    ListView {
        anchors.fill: parent
        anchors.bottomMargin: musicToolbar.mouseAreaOffset + musicToolbar.minimizedHeight
    }

    GridView {
        id: albumlist
        anchors.fill: parent
        anchors.leftMargin: units.gu(1)
        anchors.top: parent.top
        anchors.topMargin: mainView.header.height + units.gu(1)
        anchors.bottomMargin: units.gu(1)
        cellHeight: height/3
        cellWidth: height/3
        model: SortFilterModel {
            id: albumsModelFilter
            property alias rowCount: albumsModel.rowCount
            model: AlbumsModel {
                id: albumsModel
                store: musicStore
            }
            sort.property: "title"
            sort.order: Qt.AscendingOrder
        }

        delegate: albumDelegate
        flow: GridView.TopToBottom

        Component {
            id: albumDelegate
            Item {
                property string artist: model.artist
                property string album: model.title
                property var covers: [{art: model.art}]

                id: albumItem
                height: albumlist.cellHeight - units.gu(1)
                objectName: "albumsPageGridItem" + index
                width: albumlist.cellHeight - units.gu(1)
                anchors.margins: units.gu(1)

                CoverRow {
                    id: albumShape
                    anchors {
                        top: parent.top
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    count: albumItem.covers.length
                    size: albumItem.width
                    covers: albumItem.covers
                    spacing: units.gu(2)
                }
                Item {  // Background so can see text in current state
                    id: albumBg
                    anchors {
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                    }
                    height: units.gu(6)
                    clip: true
                    UbuntuShape{
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                        }
                        height: albumShape.height
                        radius: "medium"
                        color: styleMusic.common.black
                        opacity: 0.6
                    }
                }
                Label {
                    id: albumArtist
                    objectName: "albums-albumartist"
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: units.gu(1)
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(1)
                    anchors.right: parent.right
                    anchors.rightMargin: units.gu(1)
                    color: styleMusic.common.white
                    elide: Text.ElideRight
                    text: model.artist
                    fontSize: "x-small"
                }
                Label {
                    id: albumLabel
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: units.gu(3)
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(1)
                    anchors.right: parent.right
                    anchors.rightMargin: units.gu(1)
                    color: styleMusic.common.white
                    elide: Text.ElideRight
                    text: model.title
                    fontSize: "small"
                    font.weight: Font.DemiBold
                }


                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        songsPage.album = model.title;
                        songsPage.covers = [{art: model.art}]
                        songsPage.genre = undefined
                        songsPage.isAlbum = true
                        songsPage.line1 = model.artist
                        songsPage.line2 = model.title
                        songsPage.title = i18n.tr("Album")

                        mainPageStack.push(songsPage)
                    }

                    // TODO: If http://pad.lv/1354753 is fixed to expose whether the Shape should appear pressed, update this as well.
                    onPressedChanged: albumShape.pressed = pressed
                }
            }
        }
    }
}


