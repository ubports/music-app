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
import Ubuntu.Components.ListItems 1.0 as ListItem
import Ubuntu.Components.Popups 1.0
import Ubuntu.MediaScanner 0.1
import Ubuntu.Thumbnailer 0.1
import QtQuick.LocalStorage 2.0
import "../meta-database.js" as Library
import "../playlists.js" as Playlists
import "ListItemActions"

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

    property alias album: songsModel.album
    property alias genre: songsModel.genre

    state: songStackPage.line1 === i18n.tr("Playlist") ? "playlist" : "album"
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
                        var dialog = PopupUtils.open(editPlaylistDialog, mainView)
                        dialog.oldPlaylistName = line2
                    }
                },
                Action {
                    objectName: "deletePlaylist"
                    iconName: "delete"
                    onTriggered: {
                        var dialog = PopupUtils.open(removePlaylistDialog, mainView)
                        dialog.oldPlaylistName = line2
                    }
                }
            ]
            PropertyChanges {
                target: songStackPage.head
                backAction: playlistState.backAction
                actions: playlistState.actions
            }
        }
    ]

    SongsModel {
        id: songsModel
        store: musicStore
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
        header: BlurredHeader {
            rightColumn: Column {
                spacing: units.gu(2)
                Button {
                    id: shuffleRow
                    height: units.gu(4)
                    strokeColor: UbuntuColors.green
                    width: units.gu(15)
                    Text {
                        anchors {
                            centerIn: parent
                        }
                        color: "white"
                        text: i18n.tr("Shuffle")
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            shuffleModel(albumtrackslist.model)  // play track

                            if (isAlbum && songStackPage.line1 !== i18n.tr("Genre")) {
                                Library.addRecent(songStackPage.line2, songStackPage.line1, songStackPage.covers[0], songStackPage.line2, "album")
                                recentModel.filterRecent()
                            } else if (songStackPage.line1 === i18n.tr("Playlist")) {
                                Library.addRecent(songStackPage.line2, "Playlist", songStackPage.covers[0], songStackPage.line2, "playlist")
                                recentModel.filterRecent()
                            }
                        }
                    }
                }
                Button {
                    id: queueAllRow
                    height: units.gu(4)
                    strokeColor: UbuntuColors.green
                    width: units.gu(15)
                    Text {
                        anchors {
                            centerIn: parent
                        }
                        color: "white"
                        text: i18n.tr("Queue all")
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: addQueueFromModel(albumtrackslist.model)
                    }
                }
                Button {
                    id: playRow
                    color: UbuntuColors.green
                    height: units.gu(4)
                    text: i18n.tr("Play all")
                    width: units.gu(15)
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            trackClicked(albumtrackslist.model, 0)  // play track

                            if (isAlbum && songStackPage.line1 !== i18n.tr("Genre")) {
                                Library.addRecent(songStackPage.line2, songStackPage.line1, songStackPage.covers[0], songStackPage.line2, "album")
                                recentModel.filterRecent()
                            } else if (songStackPage.line1 === i18n.tr("Playlist")) {
                                Library.addRecent(songStackPage.line2, "Playlist", songStackPage.covers[0], songStackPage.line2, "playlist")
                                recentModel.filterRecent()
                            }
                        }
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
                    text: line2
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
                    text: line1
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
                    text: isAlbum && line1 !== i18n.tr("Genre")?
                              (year !== "" ? year + " | " : "") + i18n.tr("%1 song", "%1 songs", albumtrackslist.count).arg(albumtrackslist.count)
                            : i18n.tr("%1 song", "%1 songs", albumtrackslist.count).arg(albumtrackslist.count)
                    wrapMode: Text.NoWrap
                }
            }
        }

        Component {
            id: albumTracksDelegate

            ListItemWithActions {
                id: track
                color: "transparent"
                objectName: "songsPageListItem" + index
                iconFrame: false
                progression: false
                showDivider: false
                height: units.gu(6)

                leftSideAction: songStackPage.line1 === i18n.tr("Playlist")
                                ? playlistRemoveAction.item : null
                reorderable: songStackPage.line1 === i18n.tr("Playlist")
                rightSideActions: [
                    AddToQueue {

                    },
                    AddToPlaylist {

                    }
                ]
                triggerActionOnMouseRelease: true

                onItemClicked: {
                    trackClicked(albumtrackslist.model, index)  // play track

                    if (isAlbum && songStackPage.line1 !== i18n.tr("Genre")) {
                        Library.addRecent(songStackPage.line2, songStackPage.line1, model.art, songStackPage.line2, "album")
                        recentModel.filterRecent()
                    } else if (songStackPage.line1 === i18n.tr("Playlist")) {
                        Library.addRecent(songStackPage.line2, "Playlist", songStackPage.covers[0], songStackPage.line2, "playlist")
                        recentModel.filterRecent()
                    }
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

                            albumTracksModel.filterPlaylistTracks(songStackPage.line2)
                            playlistModel.filterPlaylists()
                        }
                    }
                }

                // TODO: If http://pad.lv/1354753 is fixed to expose whether the Shape should appear pressed, update this as well.
                onPressedChanged: musicRow.pressed = pressed

                MusicRow {
                    id: musicRow
                    covers: []
                    showCovers: false
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

    // Edit name of playlist dialog
    Component {
        id: editPlaylistDialog
        Dialog {
            id: dialogEditPlaylist
            // TRANSLATORS: this is a title of a dialog with a prompt to rename a playlist
            title: i18n.tr("Change name")
            text: i18n.tr("Enter the new name of the playlist.")

            property alias oldPlaylistName: playlistName.placeholderText

            TextField {
                id: playlistName
                inputMethodHints: Qt.ImhNoPredictiveText

                onPlaceholderTextChanged: text = placeholderText
            }
            Label {
                id: editplaylistoutput
                color: "red"
                visible: false
            }

            Button {
                text: i18n.tr("Change")
                color: styleMusic.dialog.confirmButtonColor
                onClicked: {
                    editplaylistoutput.visible = true

                    if (playlistName.text.length > 0) { // make sure something is acually inputed
                        console.debug("Debug: User changed name from "+playlistName.placeholderText+" to "+playlistName.text)

                        if (Playlists.renamePlaylist(playlistName.placeholderText, playlistName.text) === true) {
                            playlistModel.filterPlaylists()

                            if (Library.recentContainsPlaylist(playlistName.placeholderText)) {
                                Library.recentRenamePlaylist(playlistName.placeholderText, playlistName.text)
                                recentModel.filterRecent()
                            }

                            PopupUtils.close(dialogEditPlaylist)

                            line2 = playlistName.text
                        }
                        else {
                            editplaylistoutput.text = i18n.tr("Playlist already exists")
                        }
                    }
                    else {
                        editplaylistoutput.text = i18n.tr("Please type in a name.")
                    }
                }
            }
            Button {
                text: i18n.tr("Cancel")
                color: styleMusic.dialog.cancelButtonColor
                onClicked: PopupUtils.close(dialogEditPlaylist)
            }
        }
    }

    // Remove playlist dialog
    Component {
        id: removePlaylistDialog
        Dialog {
            id: dialogRemovePlaylist
            // TRANSLATORS: this is a title of a dialog with a prompt to delete a playlist
            title: i18n.tr("Are you sure?")
            text: i18n.tr("This will delete your playlist.")

            property string oldPlaylistName

            Button {
                text: i18n.tr("Remove")
                color: styleMusic.dialog.confirmButtonColor
                onClicked: {
                    // removing playlist
                    Playlists.removePlaylist(dialogRemovePlaylist.oldPlaylistName)

                    playlistModel.filterPlaylists();

                    if (Library.recentContainsPlaylist(dialogRemovePlaylist.oldPlaylistName)) {
                        Library.recentRemovePlaylist(dialogRemovePlaylist.oldPlaylistName)
                        recentModel.filterRecent()
                    }

                    PopupUtils.close(dialogRemovePlaylist)

                    musicToolbar.goBack()
                }
            }
            Button {
                text: i18n.tr("Cancel")
                color: styleMusic.dialog.cancelButtonColor
                onClicked: PopupUtils.close(dialogRemovePlaylist)
            }
        }
    }
}
