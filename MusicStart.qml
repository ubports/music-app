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
import "meta-database.js" as Library
import "playlists.js" as Playlists
import "common"

MusicPage {
    id: mainpage
    title: i18n.tr("Recent")

    head {
        actions: [
            Action {
                enabled: recentModel.model.count > 0
                iconName: "delete"
                onTriggered: {
                    Library.clearRecentHistory()
                    recentModel.filterRecent()
                }
            }
        ]
    }

    CardView {
        id: recentCardView
        model: recentModel.model
        delegate: Card {
            id: albumCard

            SongsModel {
                id: recentAlbumSongs
                album: model.type === "album" ? model.data : undefined
                store: musicStore
            }

            coverSources: model.type === "playlist" ? Playlists.getPlaylistCovers(model.data) : (recentAlbumSongs.status === SongsModel.Ready ? [makeDict(recentAlbumSongs.get(0, SongsModel.RoleModelData))] : [])
            objectName: "albumsPageGridItem" + index
            primaryText: model.type === "playlist" ? model.data : (recentAlbumSongs.status === SongsModel.Ready ? recentAlbumSongs.get(0, SongsModel.RoleModelData).album : "")
            secondaryText: model.type === "playlist" ? i18n.tr("Playlist") : (recentAlbumSongs.status === SongsModel.Ready ? recentAlbumSongs.get(0, SongsModel.RoleModelData).author : "")

            onClicked: {
                if (type === "playlist") {
                    albumTracksModel.filterPlaylistTracks(model.data)
                } else {
                    songsPage.album = primaryText;
                }

                songsPage.covers = coverSources
                songsPage.genre = undefined;
                songsPage.isAlbum = (model.type === "album")
                songsPage.line1 = secondaryText
                songsPage.line2 = primaryText
                songsPage.title = songsPage.isAlbum ? i18n.tr("Album") : i18n.tr("Playlist")

                mainPageStack.push(songsPage)
            }
        }
    }
}
