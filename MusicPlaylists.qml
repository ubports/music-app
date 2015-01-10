/*
 * Copyright (C) 2013, 2014, 2015
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
    state: "default"
    states: [
        PageHeadState {
            name: "default"
            head: playlistsPage.head
            actions: [
                Action {
                    objectName: "newPlaylistButton"
                    iconName: "add"
                    onTriggered: {
                        customdebug("New playlist.")
                        PopupUtils.open(newPlaylistDialog, mainView)
                    }
                },
                Action {
                    enabled: playlistModel.model.count > 0
                    iconName: "search"
                    onTriggered: playlistsPage.state = "search"
                }
            ]
        },
        SearchHeadState {
            id: searchHeader
            thisPage: playlistsPage
        }
    ]

    property bool changed: false

    onVisibleChanged: {
        if (changed) {
            changed = false
            refreshWaitTimer.start()
        }
    }

    Timer {  // FIXME: workaround for when the playlist is deleted and the delegate being deleting causes freezing
        id: refreshWaitTimer
        interval: 250
        onTriggered: playlistModel.filterPlaylists()
    }

    CardView {
        id: playlistslist
        model: SortFilterModel {
            id: playlistModelFilter
            model: playlistModel.model
            sort.property: "name"
            sort.order: Qt.AscendingOrder
            sortCaseSensitivity: Qt.CaseInsensitive
            filter.property: "name"
            filter.pattern: new RegExp(searchHeader.query, "i")
            filterCaseSensitivity: Qt.CaseInsensitive
        }
        objectName: "playlistsCardView"
        delegate: Card {
            id: playlistCard
            coverSources: Playlists.getPlaylistCovers(model.name)
            primaryText: model.name
            secondaryText: i18n.tr("%1 song", "%1 songs", model.count).arg(model.count)

            onClicked: {
                albumTracksModel.filterPlaylistTracks(model.name)

                var comp = Qt.createComponent("common/SongsPage.qml")
                var songsPage = comp.createObject(mainPageStack,
                                                  {
                                                      "album": undefined,
                                                      "covers": coverSources,
                                                      "isAlbum": false,
                                                      "genre": undefined,
                                                      "page": playlistsPage,
                                                      "title": i18n.tr("Playlist"),
                                                      "line1": i18n.tr("Playlist"),
                                                      "line2": model.name,
                                                  });

                if (songsPage == null) {  // Error Handling
                    console.log("Error creating object");
                }

                mainPageStack.push(songsPage)
            }
        }
    }
}
