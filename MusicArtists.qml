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
import "common"


Page {
    id: mainpage
    title: i18n.tr("Artists")

    onVisibleChanged: {
        if (visible === true)
        {
            musicToolbar.setPage(mainpage);
        }
    }

    MusicSettings {
        id: musicSettings
    }

    ListView {
        id: artistlist
        anchors.fill: parent
        anchors.bottomMargin: musicToolbar.mouseAreaOffset + musicToolbar.minimizedHeight
        model: artistModel.model
        delegate: artistDelegate

        Component {
            id: artistDelegate

            ListItem.Standard {
                id: track
                property string artist: model.artist
                height: styleMusic.common.itemHeight

                UbuntuShape {
                    id: cover0
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(4)
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(1)
                    width: styleMusic.common.albumSize
                    height: styleMusic.common.albumSize
                    image: Image {
                        source: Library.getArtistCovers(artist).length > 3 && Library.getArtistCovers(artist)[3] !== "" ? Library.getArtistCovers(artist)[3] : "images/cover_default.png"
                    }
                    visible: Library.getArtistCovers(artist).length > 3
                }
                UbuntuShape {
                    id: cover1
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(3)
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(1)
                    width: styleMusic.common.albumSize
                    height: styleMusic.common.albumSize
                    image: Image {
                        source: Library.getArtistCovers(artist).length > 2 && Library.getArtistCovers(artist)[2] !== "" ? Library.getArtistCovers(artist)[2] : "images/cover_default.png"
                    }
                    visible: Library.getArtistCovers(artist).length > 2
                }
                UbuntuShape {
                    id: cover2
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(2)
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(1)
                    width: styleMusic.common.albumSize
                    height: styleMusic.common.albumSize
                    image: Image {
                        source: Library.getArtistCovers(artist).length > 1 && Library.getArtistCovers(artist)[1] !== "" ? Library.getArtistCovers(artist)[1] : "images/cover_default.png"
                    }
                    visible: Library.getArtistCovers(artist).length > 1
                }
                UbuntuShape {
                    id: cover3
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(1)
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(1)
                    width: styleMusic.common.albumSize
                    height: styleMusic.common.albumSize
                    image: Image {
                        source: Library.getArtistCovers(artist).length > 0 && Library.getArtistCovers(artist)[0] !== "" ? Library.getArtistCovers(artist)[0] : "images/cover_default.png"
                    }
                }

                Label {
                    id: trackArtistAlbum
                    wrapMode: Text.NoWrap
                    maximumLineCount: 2
                    fontSize: "medium"
                    color: styleMusic.common.music
                    anchors.left: cover3.left
                    anchors.leftMargin: units.gu(14)
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(2)
                    anchors.right: parent.right
                    anchors.rightMargin: units.gu(1.5)
                    elide: Text.ElideRight
                    text: artist
                }

                Label {
                    id: trackArtistAlbums
                    wrapMode: Text.NoWrap
                    maximumLineCount: 2
                    fontSize: "x-small"
                    anchors.left: cover3.left
                    anchors.leftMargin: units.gu(14)
                    anchors.top: trackArtistAlbum.bottom
                    anchors.topMargin: units.gu(1)
                    anchors.right: parent.right
                    anchors.rightMargin: units.gu(1.5)
                    elide: Text.ElideRight
                    // model for number of albums?
                    text: i18n.tr("%1 album", "%1 albums", Library.getArtistAlbumCount(artist)).arg(Library.getArtistAlbumCount(artist))
                }

                Label {
                    id: trackArtistAlbumTracks
                    wrapMode: Text.NoWrap
                    maximumLineCount: 2
                    fontSize: "x-small"
                    anchors.left: cover3.left
                    anchors.leftMargin: units.gu(14)
                    anchors.top: trackArtistAlbums.bottom
                    anchors.topMargin: units.gu(1)
                    anchors.right: parent.right
                    anchors.rightMargin: units.gu(1.5)
                    elide: Text.ElideRight
                    text: i18n.tr("%1 song", "%1 songs", Library.getArtistTracks(artist).length).arg(Library.getArtistTracks(artist).length)
                }
                onFocusChanged: {
                }
                MouseArea {
                    anchors.fill: parent
                    onDoubleClicked: {
                    }
                    onPressAndHold: {
                    }
                    onClicked: {
                        artistAlbumsModel.filterArtistAlbums(artist)
                        artistSheet.artist = artist
                        PopupUtils.open(artistSheet.sheet)
                    }
                }
                Component.onCompleted: {
                }
            }
        }
    }
}

