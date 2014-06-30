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
 DefaultSheet {
     id: addtoPlaylist
     title: i18n.tr("Select playlist")
     contentsHeight: units.gu(80)

     onDoneClicked: PopupUtils.close(addtoPlaylist)

     Component.onCompleted:  {
         // check the four latest track in each playlist
         // get the cover art of them
         // print them in the icon
         tabs.ensurePopulated(playlistTab);
     }

     onVisibleChanged: {
         if (visible)
         {
             musicToolbar.setSheet(addtoPlaylist)
         }
         else
         {
             musicToolbar.removeSheet(addtoPlaylist)
         }
     }

     Rectangle {
         width: parent.width
         height: parent.height
         color: "transparent"
         clip: true

         // show each playlist and make them chosable
         ListView {
             id: addtoPlaylistView
             objectName: "addtoplaylistview"
             width: parent.width
             height: parent.width
             model: playlistModel.model
             delegate: ListItem.Standard {
                    id: playlist
                    objectName: "playlist"
                    height: styleMusic.common.itemHeight

                    property string name: model.name
                    property string count: model.count

                    onClicked: {
                        console.debug("Debug: "+chosenElement.filename+" added to "+name)
                        Playlists.addtoPlaylist(name,
                                                chosenElement.filename,
                                                chosenElement.author,
                                                chosenElement.title,
                                                chosenElement.album,
                                                chosenElement.art,
                                                "","","","")
                        count = Playlists.getPlaylistCount(name) // get the new count
                        playlistModel.model.set(index, {"count": count}) // update number ot tracks in playlist
                        onDoneClicked: PopupUtils.close(addtoPlaylist)
                    }

                    MusicRow {
                        covers: Playlists.getPlaylistCovers(playlist.name)
                        column: Column {
                            spacing: units.gu(1)
                            Label {
                                id: playlistCount
                                color: styleMusic.common.subtitle
                                elide: Text.ElideRight
                                fontSize: "x-small"
                                maximumLineCount: 1
                                text: i18n.tr("%1 song", "%1 songs", playlist.count).arg(playlist.count)
                                wrapMode: Text.NoWrap
                            }
                            Label {
                                id: playlistName
                                color: styleMusic.common.music
                                elide: Text.ElideRight
                                fontSize: "medium"
                                maximumLineCount: 1
                                text: playlist.name
                                wrapMode: Text.NoWrap
                            }
                        }
                    }
             }
         }

         Button {
             id: newPlaylistItem
             objectName: "newplaylistButton"
             text: i18n.tr("New playlist")
             iconSource: "images/add.svg"
             iconPosition: "left"
             width: parent.width
             anchors.bottom: parent.bottom
             anchors.bottomMargin: units.gu(0.5)
             onClicked: {
                 customdebug("New playlist.")
                 PopupUtils.open(newPlaylistDialog, mainView)
             }
         }

     }
 }
