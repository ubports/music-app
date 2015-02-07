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
import Ubuntu.Components.ListItems 1.0 as ListItem
import Ubuntu.Components.Popups 1.0
import Ubuntu.MediaScanner 0.1
import Ubuntu.Thumbnailer 0.1
import QtQuick.LocalStorage 2.0
import "../logic/meta-database.js" as Library
import "../logic/playlists.js" as Playlists
import "../components"
import "../components/HeadState"
import "../components/ListItemActions"
import "../components/ViewButton"

MusicPage {
    id: songStackPage
    objectName: "songsPage"
    visible: false

    property string line1: ""
    property string line2: ""
    property string songtitle: ""
    property var covers: []
    property bool isAlbum: false
    property string file: ""
    property string year: ""

    property var page
    property alias album: songsModel.album
    property alias artist: songsModel.albumArtist
    property alias genre: songsModel.genre

    property bool loaded: false  // used to detect difference between first and further loads

    property bool playlistChanged: false

    onVisibleChanged: {
        if (playlistChanged) {
            playlistChanged = false
            refreshWaitTimer.start()
        }
    }

    SongsModel {
        store: musicStore
        onFilled: {
            // Detect any track removals and reload the playlist
            if (songStackPage.line1 === i18n.tr("Playlist")) {
                if (songStackPage.visible) {
                    albumTracksModel.filterPlaylistTracks(line2)
                } else {
                    songStackPage.playlistChanged = true
                }
            }
        }
    }

    Timer {  // FIXME: workaround for when the playlist is deleted and the delegate being deleting causes freezing
        id: refreshWaitTimer
        interval: 250
        onTriggered: albumTracksModel.filterPlaylistTracks(line2)
    }

    function playlistChangedHelper(force)
    {
        force = force === undefined ? false : force  // default force to false

        // if parent Playlists then set changed otherwise refilter
        if (songStackPage.page.title === i18n.tr("Playlists")) {
            if (songStackPage.page !== undefined) {
                songStackPage.page.changed = true
            }
        } else {
            playlistModel.filterPlaylists()
        }

        if (Library.recentContainsPlaylist(songStackPage.line2) || force) {
            // if parent Recent then set changed otherwise refilter
            if (songStackPage.page.title === i18n.tr("Recent")) {
                if (songStackPage.page !== undefined) {
                    songStackPage.page.changed = true
                }
            } else {
                recentModel.filterRecent()
            }
        }
    }

    state: albumtrackslist.state === "multiselectable" ? "selection" : (songStackPage.line1 === i18n.tr("Playlist") ? "playlist" : "album")
    states: [
        PageHeadState {
            id: albumState
            name: "album"
            PropertyChanges {
                target: songStackPage.head
                backAction: albumState.backAction
                actions: albumState.actions
            }
        },
        PageHeadState {
            id: playlistState
            name: "playlist"
            actions: [
                Action {
                    objectName: "editPlaylist"
                    iconName: "edit"
                    onTriggered: {
                        var dialog = PopupUtils.open(Qt.resolvedUrl("../components/Dialog/EditPlaylistDialog.qml"), mainView)
                        dialog.oldPlaylistName = line2
                    }
                },
                Action {
                    objectName: "deletePlaylist"
                    iconName: "delete"
                    onTriggered: {
                        var dialog = PopupUtils.open(Qt.resolvedUrl("../components/Dialog/RemovePlaylistDialog.qml"), mainView)
                        dialog.oldPlaylistName = line2
                    }
                }
            ]
            PropertyChanges {
                target: songStackPage.head
                backAction: playlistState.backAction
                actions: playlistState.actions
            }
        },
        MultiSelectHeadState {
            listview: albumtrackslist
            removable: songStackPage.line1 === i18n.tr("Playlist")
            thisPage: songStackPage

            onRemoved: {
                for (var i=0; i < selectedItems.length; i++) {
                    Playlists.removeFromPlaylist(songStackPage.line2, selectedItems[i])

                    // Update indexes as an index has been removed
                    for (var j=i + 1; j < selectedItems.length; j++) {
                        if (selectedItems[j] > selectedItems[i]) {
                            selectedItems[j]--;
                        }
                    }
                }

                playlistChangedHelper()  // update recent/playlist models

                albumTracksModel.filterPlaylistTracks(songStackPage.line2)

                // refresh cover art
                songStackPage.covers = Playlists.getPlaylistCovers(songStackPage.line2)
            }
        }
    ]

    SongsModel {
        id: songsModel
        store: musicStore
        onStatusChanged: {
            if (songsModel.status === SongsModel.Ready && loaded && songsModel.count === 0) {
                mainPageStack.popPage(songStackPage)
            }
        }
    }

    ListView {
        id: albumtrackslist
        anchors {
            fill: parent
        }
        delegate: albumTracksDelegate
        model: isAlbum ? songsModel : albumTracksModel.model
        objectName: "songspage-listview"
        width: parent.width

        // Requirements for ListItemWithActions
        property var selectedItems: []

        signal clearSelection()
        signal closeSelection()
        signal selectAll()

        onClearSelection: selectedItems = []
        onCloseSelection: {
            clearSelection()
            state = "normal"
        }
        onSelectAll: {
            var tmp = selectedItems

            for (var i=0; i < model.count; i++) {
                if (tmp.indexOf(i) === -1) {
                    tmp.push(i)
                }
            }

            selectedItems = tmp
        }
        onVisibleChanged: {
            if (!visible) {
                closeSelection()
            }
        }

        Component.onCompleted: {
            // FIXME: workaround for qtubuntu not returning values depending on the grid unit definition
            // for Flickable.maximumFlickVelocity and Flickable.flickDeceleration
            var scaleFactor = units.gridUnit / 8;
            maximumFlickVelocity = maximumFlickVelocity * scaleFactor;
            flickDeceleration = flickDeceleration * scaleFactor;
        }

        header: BlurredHeader {
            rightColumn: Column {
                spacing: units.gu(2)
                ShuffleButton {
                    model: albumtrackslist.model
                    onClicked: {
                        if (isAlbum && songStackPage.line1 !== i18n.tr("Genre")) {
                            Library.addRecent(albumtrackslist.model.get(0, albumtrackslist.model.RoleModelData).album, "album")
                        } else if (songStackPage.line1 === i18n.tr("Playlist")) {
                            Library.addRecent(songStackPage.line2, "playlist")
                        } else {
                            console.debug("Unknown type to add to recent")
                        }

                        recentModel.filterRecent()
                    }
                }
                QueueAllButton {
                    model: albumtrackslist.model
                }
                PlayAllButton {
                    model: albumtrackslist.model
                    onClicked: {
                        if (isAlbum && songStackPage.line1 !== i18n.tr("Genre")) {
                            Library.addRecent(albumtrackslist.model.get(0, albumtrackslist.model.RoleModelData).album, "album")
                        } else if (songStackPage.line1 === i18n.tr("Playlist")) {
                            Library.addRecent(songStackPage.line2, "playlist")
                        } else {
                            console.debug("Unknown type to add to recent")
                        }

                        recentModel.filterRecent()
                    }
                }
            }
            coverSources: songStackPage.covers
            height: songStackPage.line1 !== i18n.tr("Playlist") &&
                    songStackPage.line1 !== i18n.tr("Genre") ?
                        units.gu(33) : units.gu(30)
            bottomColumn: Column {
                Label {
                    id: albumLabel
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    color: styleMusic.common.music
                    elide: Text.ElideRight
                    fontSize: "x-large"
                    maximumLineCount: 1
                    text: line2 != "" ? line2 : i18n.tr("Unknown Album")
                    wrapMode: Text.NoWrap
                }

                Item {
                    height: units.gu(0.75)
                    width: parent.width
                    visible: albumArtist.visible
                }

                Label {
                    id: albumArtist
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    color: styleMusic.common.subtitle
                    elide: Text.ElideRight
                    fontSize: "small"
                    maximumLineCount: 1
                    objectName: "songsPageHeaderAlbumArtist"
                    text: line1 != "" ? line1 : i18n.tr("Unknown Artist")
                    visible: text !== i18n.tr("Playlist") &&
                             text !== i18n.tr("Genre")
                    wrapMode: Text.NoWrap
                }

                Item {
                    height: units.gu(1)
                    width: parent.width
                }

                Label {
                    id: albumYear
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    color: styleMusic.common.subtitle
                    elide: Text.ElideRight
                    fontSize: "small"
                    maximumLineCount: 1
                    text: isAlbum && line1 !== i18n.tr("Genre")
                          ? (year !== "" ? year + " | " : "") + i18n.tr("%1 song", "%1 songs", albumtrackslist.count).arg(albumtrackslist.count)
                          : i18n.tr("%1 song", "%1 songs", albumtrackslist.count).arg(albumtrackslist.count)
                    wrapMode: Text.NoWrap
                }
            }
        }

        Component {
            id: albumTracksDelegate

            ListItemWithActions {
                id: track
                objectName: "songsPageListItem" + index
                height: units.gu(6)

                leftSideAction: songStackPage.line1 === i18n.tr("Playlist")
                                ? playlistRemoveAction.item : null
                multiselectable: true
                reorderable: songStackPage.line1 === i18n.tr("Playlist")
                rightSideActions: [
                    AddToQueue {

                    },
                    AddToPlaylist {

                    }
                ]

                onItemClicked: {
                    trackClicked(albumtrackslist.model, index)  // play track

                    if (isAlbum && songStackPage.line1 !== i18n.tr("Genre")) {
                        Library.addRecent(albumtrackslist.model.get(0, albumtrackslist.model.RoleModelData).album, "album")
                    } else if (songStackPage.line1 === i18n.tr("Playlist")) {
                        Library.addRecent(songStackPage.line2, "playlist")
                    } else {
                        console.debug("Unknown type to add to recent")
                    }

                    recentModel.filterRecent()
                }
                onReorder: {
                    console.debug("Move: ", from, to);

                    Playlists.move(songStackPage.line2, from, to)

                    albumTracksModel.filterPlaylistTracks(songStackPage.line2)
                }

                Loader {
                    id: playlistRemoveAction
                    sourceComponent: Remove {
                        onTriggered: {
                            Playlists.removeFromPlaylist(songStackPage.line2, model.i)

                            playlistChangedHelper()  // update recent/playlist models

                            albumTracksModel.filterPlaylistTracks(songStackPage.line2)

                            // refresh cover art
                            songStackPage.covers = Playlists.getPlaylistCovers(songStackPage.line2)
                        }
                    }
                }

                MusicRow {
                    id: musicRow
                    height: parent.height
                    column: Column {
                        Label {
                            id: trackTitle
                            color: styleMusic.common.music
                            fontSize: "small"
                            objectName: "songspage-tracktitle"
                            text: model.title
                        }

                        Label {
                            id: trackArtist
                            color: styleMusic.common.subtitle
                            fontSize: "x-small"
                            text: model.author
                        }
                    }
                }

                Component.onCompleted: {
                    if (model.date !== undefined)
                    {
                        songStackPage.file = model.filename;
                        songStackPage.year = new Date(model.date).toLocaleString(Qt.locale(),'yyyy');
                    }
                }
            }
        }
    }

    Component.onCompleted: loaded = true
}
