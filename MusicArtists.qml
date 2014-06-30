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
                    delegate: Item {
                        property string author: model.artist
                        property string album: model.title
                    }
                    property var covers: []
                    signal finished()

                    onFinished: {
                        musicRow.covers = covers
                    }
                    onItemAdded: {
                        covers.push({author: item.author, album: item.album});

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

                MusicRow {
                    id: musicRow
                    column: Column {
                        spacing: units.gu(1)
                        Label {
                            id: trackArtistAlbum
                            color: styleMusic.common.music
                            elide: Text.ElideRight
                            fontSize: "medium"
                            maximumLineCount: 2
                            objectName: "artists-artist"
                            text: model.artist
                            wrapMode: Text.NoWrap
                        }
                        Label {
                            id: trackArtistAlbums
                            color: styleMusic.common.subtitle
                            elide: Text.ElideRight
                            fontSize: "x-small"
                            maximumLineCount: 2
                            text: i18n.tr("%1 album", "%1 albums", albumArtistModel.rowCount).arg(albumArtistModel.rowCount)
                            wrapMode: Text.NoWrap
                        }
                        Label {
                            id: trackArtistAlbumTracks
                            color: styleMusic.common.subtitle
                            elide: Text.ElideRight
                            fontSize: "x-small"
                            maximumLineCount: 2
                            text: i18n.tr("%1 song", "%1 songs", songArtistModel.rowCount).arg(songArtistModel.rowCount)
                            wrapMode: Text.NoWrap
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        artistSheet.artist = model.artist
                        artistSheet.covers = musicRow.covers
                        PopupUtils.open(artistSheet.sheet)
                    }
                }
            }
        }
    }
}

