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
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import "settings.js" as Settings
import "meta-database.js" as Library
import "playlists.js" as Playlists
import "common"


MusicPage {
    id: mainpage
    objectName: "artistsPage"
    title: i18n.tr("Artists")

    ListView {
        id: artistlist
        anchors {
            fill: parent
        }
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
                objectName: "artistsPageListItem" + index
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
                        property string art: model.art
                    }
                    property var covers: []
                    signal finished()

                    onFinished: {
                        musicRow.covers = covers
                    }
                    onItemAdded: {
                        covers.push({art: item.art});

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
                            fontSize: "medium"
                            objectName: "artists-artist"
                            text: model.artist
                        }
                        Label {
                            id: trackArtistAlbums
                            color: styleMusic.common.subtitle
                            fontSize: "x-small"
                            text: i18n.tr("%1 album", "%1 albums", albumArtistModel.rowCount).arg(albumArtistModel.rowCount)
                        }
                        Label {
                            id: trackArtistAlbumTracks
                            color: styleMusic.common.subtitle
                            fontSize: "x-small"
                            text: i18n.tr("%1 song", "%1 songs", songArtistModel.rowCount).arg(songArtistModel.rowCount)
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        albumsPage.artist = model.artist
                        albumsPage.covers = musicRow.covers
                        albumsPage.title = i18n.tr("Artist")

                        mainPageStack.push(albumsPage)
                    }

                    // TODO: If http://pad.lv/1354753 is fixed to expose whether the Shape should appear pressed, update this as well.
                    onPressedChanged: musicRow.pressed = pressed
                }
            }
        }
    }
}

