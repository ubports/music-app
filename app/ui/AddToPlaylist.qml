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

import QtMultimedia 5.0
import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.0 as ListItem
import Ubuntu.Components.Popups 1.0
import QtQuick.LocalStorage 2.0
import "../logic/meta-database.js" as Library
import "../logic/playlists.js" as Playlists
import "../components"
import "../components/Delegates"
import "../components/Flickables"
import "../components/HeadState"


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
    // TRANSLATORS: this appears in the header with limited space (around 20 characters)
    title: i18n.tr("Select playlist")
    searchable: true
    searchResultsCount: addToPlaylistModelFilter.count
    state: "default"
    states: [
        PlaylistsHeadState {
            newPlaylistEnabled: allSongsModel.count > 0
            searchEnabled: playlistModel.model.count > 0 && allSongsModel.count > 0
            thisPage: addToPlaylistPage
        },
        SearchHeadState {
            id: searchHeader
            thisPage: addToPlaylistPage
        }
    ]

    property var chosenElements: []

    onVisibleChanged: {
        // Load the playlistmodel if it hasn't loaded or is empty
        if (visible && (!playlistModel.completed || playlistModel.model.count === 0)) {
            playlistModel.canLoad = true  // ensure the model canLoad
            playlistModel.filterPlaylists()
        }
    }

    CardView {
        id: addtoPlaylistView
        itemWidth: units.gu(12)
        model: SortFilterModel {
            // Sorting disabled as it is incorrect on first run (due to workers?)
            // and SQL sorts the data correctly
            id: addToPlaylistModelFilter
            model: playlistModel.model
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
                Playlists.addToPlaylistList(name, chosenElements)

                if (tabs.selectedTab.title === i18n.tr("Playlists")) {
                    // If we are on a page above playlists then set changed
                    tabs.selectedTab.page.changed = true;
                    tabs.selectedTab.page.childrenChanged = true;
                } else {
                    // Otherwise just reload the playlists
                    playlistModel.filterPlaylists();
                }

                if (Library.recentContainsPlaylist(name)) {
                    if (tabs.selectedTab.title === i18n.tr("Recent")) {
                        // If we are on a page above recent then set changed
                        tabs.selectedTab.page.changed = true;
                        tabs.selectedTab.page.childrenChanged = true;
                    } else {
                        // Otherwise just reload recent
                        recentModel.filterRecent();
                    }
                }

                mainPageStack.goBack();  // go back to the previous page
            }
        }
    }

    // Overlay to show when no playlists are on the device
    Loader {
        anchors {
            fill: parent
            topMargin: -playlistsPage.header.height
        }
        active: playlistModel.model.count === 0 && playlistModel.workerComplete
        asynchronous: true
        source: "../components/PlaylistsEmptyState.qml"
        visible: active
    }
}
