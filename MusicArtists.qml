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
import Ubuntu.MediaScanner 0.1
import Ubuntu.Thumbnailer 0.1
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
        model: ArtistsModel {
            id: artistsModel
            albumArtists: true
            store: musicStore
        }

        delegate: artistDelegate

        Component {
            id: artistDelegate

            ListItem.Standard {
                id: track
                height: styleMusic.common.itemHeight

                AlbumsModel {
                    id: albumArtistModel
                    albumArtist: model.artist
                    store: musicStore
                }

                Repeater {
                    id: albumArtistModelRepeater
                    model: albumArtistModel
                    delegate: Text { text: model.art; visible: false}
                    property var covers: []
                    signal finished()

                    onFinished: {
                        coverRow.count = count
                        coverRow.covers = covers
                    }
                    onItemAdded: {
                        covers.push(item.text);

                        if (index === count - 1) {
                            finished();
                        }
                    }
                }

                SongsModel {
                    id: songArtistModel
                    albumArtist: model.artist
                    store: musicStore
                }
                Repeater {
                    id: songArtistModelRepeater
                    model: songArtistModel
                    delegate: Item { }
                }

                CoverRow {
                    id: coverRow
                    anchors {
                        top: parent.top
                        left: parent.left
                        margins: units.gu(1)
                    }

                    count: 0
                    size: styleMusic.common.albumSize
                    covers: []
                }

                Label {
                    id: trackArtistAlbum
                    objectName: "artists-artist"
                    wrapMode: Text.NoWrap
                    maximumLineCount: 2
                    fontSize: "medium"
                    color: styleMusic.common.music
                    anchors {
                        left: coverRow.right
                        leftMargin: units.gu(2)
                        top: parent.top
                        topMargin: units.gu(2)
                        right: parent.right
                        rightMargin: units.gu(1.5)
                    }
                    elide: Text.ElideRight
                    text: model.artist
                }

                Label {
                    id: trackArtistAlbums
                    wrapMode: Text.NoWrap
                    maximumLineCount: 2
                    fontSize: "x-small"
                    color: styleMusic.common.subtitle
                    anchors {
                        left: trackArtistAlbum.left
                        top: trackArtistAlbum.bottom
                        topMargin: units.gu(1)
                        right: parent.right
                        rightMargin: units.gu(1.5)
                    }
                    elide: Text.ElideRight
                    text: i18n.tr("%1 album", "%1 albums", albumArtistModelRepeater.count).arg(albumArtistModelRepeater.count)
                }

                Label {
                    id: trackArtistAlbumTracks
                    wrapMode: Text.NoWrap
                    maximumLineCount: 2
                    fontSize: "x-small"
                    color: styleMusic.common.subtitle
                    anchors {
                        left: trackArtistAlbum.left
                        top: trackArtistAlbums.bottom
                        topMargin: units.gu(1)
                        right: parent.right
                        rightMargin: units.gu(1.5)
                    }
                    elide: Text.ElideRight
                    text: i18n.tr("%1 song", "%1 songs", songArtistModelRepeater.count).arg(songArtistModelRepeater.count)
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
                        artistSheet.artist = model.artist
                        PopupUtils.open(artistSheet.sheet)
                    }
                }
            }
        }
    }
}

