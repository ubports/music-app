/*
 * Copyright (C) 2013, 2014, 2015
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
import QtQuick.LocalStorage 2.0
import "logic/meta-database.js" as Library
import "logic/playlists.js" as Playlists
import "components"


MusicPage {
    id: artistsPage
    objectName: "artistsPage"
    title: i18n.tr("Artists")
    searchable: true
    searchResultsCount: artistsModelFilter.count
    state: "default"
    states: [
        PageHeadState {
            name: "default"
            head: artistsPage.head
            actions: Action {
                enabled: artistsModelFilter.count > 0
                iconName: "search"
                onTriggered: artistsPage.state = "search"
            }
        },
        SearchHeadState {
            id: searchHeader
            thisPage: artistsPage
        }
    ]

    CardView {
        id: artistCardView
        itemWidth: units.gu(12)
        model: SortFilterModel {
            id: artistsModelFilter
            property alias rowCount: artistsModel.rowCount
            model: ArtistsModel {
                id: artistsModel
                albumArtists: true
                store: musicStore
            }
            sort.property: "artist"
            sort.order: Qt.AscendingOrder
            sortCaseSensitivity: Qt.CaseInsensitive
            filter.property: "artist"
            filter.pattern: new RegExp(searchHeader.query, "i")
            filterCaseSensitivity: Qt.CaseInsensitive
        }
        delegate: Card {
            id: artistCard
            coverSources: [{art: "image://artistart/artist=" + model.artist + "&album=" + artistCard.album}]
            objectName: "artistsPageGridItem" + index
            primaryText: model.artist != "" ? model.artist : i18n.tr("Unknown Artist")
            secondaryTextVisible: false

            property string album: ""

            AlbumsModel {
                id: albumArtistModel
                albumArtist: model.artist
                store: musicStore
            }

            Repeater {
                id: albumArtistModelRepeater
                model: albumArtistModel
                delegate: Item {
                    property string album: model.title
                }

                onItemAdded: {
                    artistCard.album = item.album
                }
            }


            onClicked: {
                var comp = Qt.createComponent("components/AlbumsPage.qml")
                var albumsPage = comp.createObject(mainPageStack,
                                                  {
                                                      "artist": model.artist,
                                                      "covers": artistCard.coverSources,
                                                      "title": i18n.tr("Artist"),
                                                  });

                if (albumsPage == null) {  // Error Handling
                    console.log("Error creating object");
                }

                mainPageStack.push(albumsPage)
            }
        }
    }
}

