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
import "settings.js" as Settings
import "scrobble.js" as Scrobble
import "playlists.js" as Playlists
import "common"
import "common/ListItemActions"

// page for the playlists
MusicPage {
    id: listspage
    objectName: "playlistsPage"
    // TRANSLATORS: this is the name of the playlists page shown in the tab header.
    // Remember to keep the translation short to fit the screen width
    title: i18n.tr("Playlists")

    property string playlistTracks: ""
    property string oldPlaylistName: ""
    property string inPlaylist: ""

    tools: ToolbarItems {
        ToolbarButton {
            action: Action {
                objectName: "newplaylistButton"
                text: i18n.tr("New playlist")
                iconName: "add"
                onTriggered: {
                    customdebug("New playlist.")
                    PopupUtils.open(newPlaylistDialog, mainView)
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
            TextField {
                id: playlistName
                placeholderText: oldPlaylistName
                inputMethodHints: Qt.ImhNoPredictiveText
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
                        console.debug("Debug: User changed name from "+oldPlaylistName+" to "+playlistName.text)

                        if (Playlists.renamePlaylist(oldPlaylistName, playlistName.text) === true) {
                            playlistModel.filterPlaylists()

                            PopupUtils.close(dialogEditPlaylist)

                            if (inPlaylist) {
                                playlistInfoLabel.text = playlistName.text
                            }
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

    MusicSettings {
        id: musicSettings
    }

    ListView {
        id: playlistslist
        objectName: "playlistsListView"
        anchors.fill: parent
        anchors.bottomMargin: musicToolbar.mouseAreaOffset + musicToolbar.minimizedHeight
        model: playlistModel.model
        delegate: playlistDelegate
        onCountChanged: {
            customdebug("onCountChanged: " + playlistslist.count)
        }
        onCurrentIndexChanged: {
            customdebug("tracklist.currentIndex = " + playlistslist.currentIndex)
        }

        Component {
            id: playlistDelegate
            ListItemWithActions {
                id: playlist
                property string name: model.name
                property string count: model.count
                property var covers: Playlists.getPlaylistCovers(name)

                color: "transparent"
                height: styleMusic.common.itemHeight
                width: parent.width

                leftSideAction: DeletePlaylist {
                    onTriggered: {
                        Playlists.removePlaylist(model.name)

                        playlistModel.filterPlaylists();
                    }
                }

                rightSideActions: [
                    EditPlaylist {
                    }
                ]
                triggerActionOnMouseRelease: true

                onItemClicked: {
                    albumTracksModel.filterPlaylistTracks(name)
                    songsPage.isAlbum = false
                    songsPage.line1 = i18n.tr("Playlist")
                    songsPage.line2 = model.name
                    songsPage.covers =  playlist.covers
                    songsPage.genre = undefined
                    songsPage.title = i18n.tr("Playlist")

                    mainPageStack.push(songsPage)
                }

                // TODO: If http://pad.lv/1354753 is fixed to expose whether the Shape should appear pressed, update this as well.
                onPressedChanged: musicRow.pressed = pressed

                MusicRow {
                    id: musicRow
                    covers: playlist.covers
                    column: Column {
                        spacing: units.gu(1)
                        Label {
                            id: playlistCount
                            color: styleMusic.common.subtitle
                            fontSize: "x-small"
                            text: i18n.tr("%1 song", "%1 songs", playlist.count).arg(playlist.count)
                        }
                        Label {
                            id: playlistName
                            color: styleMusic.common.music
                            fontSize: "medium"
                            text: playlist.name
                        }
                    }
                }
            }
        }
    }
}
