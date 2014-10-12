/*
 * Copyright (C) 2013, 2014
 *      Andrew Hayzen <ahayzen@gmail.com>
 *      Daniel Holm <d.holmen@gmail.com>
 *      Victor Thompson <victor.thompson@gmail.com>
 *
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
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import "playlists.js" as Playlists
import "common"

// page for the playlists
MusicPage {
    id: playlistsPage
    objectName: "playlistsPage"
    // TRANSLATORS: this is the name of the playlists page shown in the tab header.
    // Remember to keep the translation short to fit the screen width
    title: i18n.tr("Playlists")

    property string playlistTracks: ""
    property string inPlaylist: ""

    head {
        actions: [
            Action {
                objectName: "newplaylistButton"
                iconName: "add"
                onTriggered: {
                    customdebug("New playlist.")
                    PopupUtils.open(newPlaylistDialog, mainView)
                }
            }
        ]
    }

    CardView {
        id: playlistslist
        model: playlistModel.model
        objectName: "playlistsListView"
        delegate: Card {
            id: playlistCard
            coverSources: Playlists.getPlaylistCovers(name)
            primaryText: name
            secondaryText: i18n.tr("%1 song", "%1 songs", count).arg(count)

            onClicked: {
                albumTracksModel.filterPlaylistTracks(name)
                songsPage.isAlbum = false
                songsPage.line1 = i18n.tr("Playlist")
                songsPage.line2 = model.name
                songsPage.covers = coverSources
                songsPage.genre = undefined
                songsPage.title = i18n.tr("Playlist")

                mainPageStack.push(songsPage)
            }
        }
    }
}
