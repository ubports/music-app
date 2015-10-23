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

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import QtQuick.LocalStorage 2.0
import "../../logic/meta-database.js" as Library
import "../../logic/playlists.js" as Playlists

Dialog {
    id: dialogEditPlaylist
    // TRANSLATORS: this is a title of a dialog with a prompt to rename a playlist
    title: i18n.tr("Rename playlist")

    property string oldPlaylistName: ""

    TextField {
        id: playlistName
        inputMethodHints: Qt.ImhNoPredictiveText
        placeholderText: i18n.tr("Enter playlist name")
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

                    if (Library.recentContainsPlaylist(oldPlaylistName)) {
                        Library.recentRenamePlaylist(oldPlaylistName, playlistName.text)
                    }

                    line2 = playlistName.text

                    playlistChangedHelper()  // update recent/playlist models

                    PopupUtils.close(dialogEditPlaylist)
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

    Component.onCompleted: playlistName.forceActiveFocus()
}
