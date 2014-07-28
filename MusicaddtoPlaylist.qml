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
import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Components.Popups 0.1
import QtQuick.LocalStorage 2.0
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
    id: addtoPlaylist
    title: i18n.tr("Select playlist")
    visible: false

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

    onVisibleChanged: {
        if (visible) {
            tabs.ensurePopulated(playlistTab)
        }
    }

    // show each playlist and make them chosable
    ListView {
        id: addtoPlaylistView
        anchors {
            bottomMargin: musicToolbar.mouseAreaOffset + musicToolbar.minimizedHeight
            fill: parent
        }
        clip: true
        height: parent.width
        model: playlistModel.model
        objectName: "addtoplaylistview"
        width: parent.width
        delegate: ListItem.Standard {
            id: playlist
            objectName: "playlist"
            height: styleMusic.common.itemHeight

            property string name: model.name
            property string count: model.count

            onClicked: {
                console.debug("Debug: "+chosenElement.filename+" added to "+name)

                Playlists.addToPlaylist(name, chosenElement)

                playlistModel.filterPlaylists();

                musicToolbar.goBack();  // go back to the previous page
            }

            MusicRow {
                covers: Playlists.getPlaylistCovers(playlist.name)
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
