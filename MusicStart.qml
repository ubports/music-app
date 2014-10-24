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
            coverSources: model.type === "playlist" ? Playlists.getPlaylistCovers(title) : (model.art !== undefined ? [{art: model.art}] : [{author: model.title2, album: model.title}])
            objectName: "albumsPageGridItem" + index
            primaryText: model.title
            secondaryText: model.title2  !== "Playlist" ? model.title2 : i18n.tr("Playlist")

            onClicked: {
                if (type === "playlist") {
                    albumTracksModel.filterPlaylistTracks(model.key)
                }

                var comp = Qt.createComponent("common/SongsPage.qml")
                var songsPage = comp.createObject(mainPageStack,
                                                  {
                                                      "album": type !== "playlist" ? title : undefined,
                                                      "covers": coverSources,
                                                      "isAlbum": (type === "album"),
                                                      "genre": undefined,
                                                      "title": (type === "album") ? i18n.tr("Album") : i18n.tr("Playlist"),
                                                      "line1": secondaryText,
                                                      "line2": primaryText,
                                                  });

                if (songsPage === null) {  // Error Handling
                    console.log("Error creating object");
                }

                mainPageStack.push(songsPage)
            }
        }
    }
}
