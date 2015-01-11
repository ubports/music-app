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

import QtMultimedia 5.0
import QtQuick 2.3
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0 as ListItem
import Ubuntu.Components.Popups 1.0
import QtQuick.LocalStorage 2.0
import "meta-database.js" as Library
import "playlists.js" as Playlists
import "common"


/* NOTE:
* Text is barly visible as of right now and a bug report has been filed:
* https://bugs.launchpad.net/ubuntu-ui-toolkit/+bug/1225778
*
* Wait until the bug is resolved, or move on to use other stuff then ListItems.
*/

// Page that will be used when adding tracks to playlists
MusicPage {
    id: addToPlaylistPage
    objectName: "addToPlaylistPage"
    title: i18n.tr("Select playlist")
    searchable: true
    searchResultsCount: addToPlaylistModelFilter.count
    state: "default"
    states: [
        PageHeadState {
            name: "default"
            head: addToPlaylistPage.head
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
                    onTriggered: addToPlaylistPage.state = "search"
                }
            ]
        },
        SearchHeadState {
            id: searchHeader
            thisPage: addToPlaylistPage
        }
    ]

    property var chosenElements: []
    property var page

    onVisibleChanged: {
        if (visible) {
            playlistModel.canLoad = true  // ensure the model canLoad
            playlistModel.filterPlaylists()
        }
    }

    CardView {
        id: addtoPlaylistView
        itemWidth: units.gu(12)
        model: SortFilterModel {
            id: addToPlaylistModelFilter
            model: playlistModel.model
            sort.property: "name"
            sort.order: Qt.AscendingOrder
            sortCaseSensitivity: Qt.CaseInsensitive
            filter.property: "name"
            filter.pattern: new RegExp(searchHeader.query, "i")
            filterCaseSensitivity: Qt.CaseInsensitive
        }
        objectName: "addToPlaylistCardView"
        delegate: Card {
            id: playlist
            coverSources: Playlists.getPlaylistCovers(playlist.name)
            objectName: "addToPlaylistCardItem" + index
            property string name: model.name
            property string count: model.count

            primaryText: playlist.name
            secondaryText: i18n.tr("%1 song", "%1 songs", playlist.count).arg(playlist.count)

            onClicked: {
                for (var i=0; i < chosenElements.length; i++) {
                    console.debug("Debug: "+chosenElements[i].filename+" added to "+name)

                    Playlists.addToPlaylist(name, chosenElements[i])
                }

                // Check that the parent parent page is not being refiltered
                if (page !== undefined && page.page !== undefined && page.page.title === i18n.tr("Playlists")) {
                    page.page.changed = true
                } else {
                    playlistModel.filterPlaylists();
                }

                if (Library.recentContainsPlaylist(name)) {
                    // Check that the parent parent page is not being refiltered
                    if (page !== undefined && page.page !== undefined && page.page.title === i18n.tr("Recent")) {
                        page.page.changed = true
                    } else {
                        recentModel.filterRecent()
                    }
                }

                if (page !== undefined && name === page.line2 && page.playlistChanged !== undefined) {
                    page.playlistChanged = true
                    page.covers = Playlists.getPlaylistCovers(name)
                }

                musicToolbar.goBack();  // go back to the previous page
            }
        }
    }
}
