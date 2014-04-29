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

    onVisibleChanged: {
        if (visible === true)
        {
            musicToolbar.setPage(mainpage);
        }
    }

    MusicSettings {
        id: musicSettings
    }

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
        model: albumModel.model
        delegate: albumDelegate
        flow: GridView.TopToBottom

        Component {
            id: albumDelegate
            Item {
                property string artist: model.artist
                property string album: model.album
                property string title: model.title
                property string cover: model.cover  !== "" ? model.cover :  Qt.resolvedUrl("images/music-app-cover@30.png")
                property string length: model.length
                property string file: model.file
                property string year: model.year

                id: albumItem
                height: albumlist.cellHeight - units.gu(1)
                width: albumlist.cellHeight - units.gu(1)
                anchors.margins: units.gu(1)
                UbuntuShape {
                    id: albumShape
                    height: albumItem.width
                    width: albumItem.width
                    image: Image {
                        id: icon
                        fillMode: Image.Stretch
                        source: cover
                        onStatusChanged: {
                            if (status === Image.Error) {
                                source = Qt.resolvedUrl("images/music-app-cover@30.png")
                            }
                        }
                    }
                    UbuntuShape {  // Background so can see text in current state
                        id: albumBg2
                        anchors.bottom: parent.bottom
                        color: styleMusic.common.black
                        height: units.gu(4)
                        width: parent.width
                    }
                    Rectangle {  // Background so can see text in current state
                        id: albumBg
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: units.gu(2)
                        color: styleMusic.common.black
                        height: units.gu(3)
                        width: parent.width
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
                        color: styleMusic.nowPlaying.labelSecondaryColor
                        elide: Text.ElideRight
                        text: artist
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
                        text: album
                        fontSize: "small"
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

                        songsSheet.line1 = artist
                        songsSheet.line2 = album
                        songsSheet.isAlbum = true
                        songsSheet.file = file
                        songsSheet.year = year
                        songsSheet.covers = [cover]
                        PopupUtils.open(songsSheet.sheet)
                    }
                }
            }
        }
    }
}


