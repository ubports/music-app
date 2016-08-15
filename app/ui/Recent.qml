/*
 * Copyright (C) 2013, 2014, 2015, 2016
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

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.MediaScanner 0.1
import Ubuntu.Thumbnailer 0.1
import QtQuick.LocalStorage 2.0
import "../logic/meta-database.js" as Library
import "../logic/playlists.js" as Playlists
import "../components"
import "../components/Delegates"
import "../components/Flickables"

MusicPage {
    id: recentPage
    objectName: "recentPage"
    header: PageHeader {
        flickable: recentPage.flickable
        leadingActionBar {
            actions: {
                if (mainPageStack.currentPage === tabs) {
                    tabs.tabActions
                } else if (mainPageStack.depth > 1) {
                    backActionComponent
                } else {
                    null
                }
            }
            objectName: "tabsLeadingActionBar"
        }
        title: recentPage.title
        trailingActionBar {
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

        Action {
            id: backActionComponent
            iconName: "back"
            objectName: "backAction"
            onTriggered: mainPageStack.pop()
        }

        StyleHints {
            backgroundColor: mainView.headerColor
            dividerColor: Qt.darker(mainView.headerColor, 1.1)
        }
    }
    title: i18n.tr("Recent")

    // FIXME: workaround for pad.lv/1531016 (gridview juddery)
    anchors {
        bottom: parent.bottom
        fill: undefined
        left: parent.left
        top: parent.top
    }
    height: mainPageStack.height
    width: mainPageStack.width

    property bool changed: false
    property bool childrenChanged: false

    onVisibleChanged: {
        if (changed) {
            changed = false
            refreshWaitTimer.start()
        }
    }

    Timer {  // FIXME: workaround for when the playlist is deleted and the delegate being deleting causes freezing
        id: refreshWaitTimer
        interval: 250
        onTriggered: recentModel.filterRecent()
    }

    MusicGridView {
        id: recentGridView
        itemWidth: units.gu(15)
        heightOffset: units.gu(9.5)
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
            primaryText: model.type === "playlist" ? model.data : (recentAlbumSongs.status === SongsModel.Ready && recentAlbumSongs.get(0, SongsModel.RoleModelData).album != "" ? recentAlbumSongs.get(0, SongsModel.RoleModeData).album : i18n.tr("Unknown Album"))
            secondaryText: model.type === "playlist" ? i18n.tr("Playlist") : (recentAlbumSongs.status === SongsModel.Ready && recentAlbumSongs.get(0, SongsModel.RoleModelData).author != "" ? recentAlbumSongs.get(0, SongsModel.RoleModelData).author : i18n.tr("Unknown Artist"))

            onClicked: {
                if (model.type === "playlist") {
                    albumTracksModel.filterPlaylistTracks(model.data)
                }

                mainPageStack.push(Qt.resolvedUrl("SongsView.qml"),
                                   {
                                       "album": model.type !== "playlist" ? model.data : undefined,
                                       "artist": model.type !== "playlist" ? recentAlbumSongs.get(0, SongsModel.RoleModelData).artist : undefined,
                                       "covers": coverSources,
                                       "isAlbum": (model.type === "album"),
                                       "genre": undefined,
                                       "page": recentPage,
                                       "title": (model.type === "album") ? i18n.tr("Album") : i18n.tr("Playlist"),
                                       "line1": secondaryText,
                                       "line2": primaryText,
                                   })
            }
        }
    }
}
