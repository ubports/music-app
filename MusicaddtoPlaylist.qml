/*
 * Copyright (C) 2013 Andrew Hayzen <ahayzen@gmail.com>
 *                    Daniel Holm <d.holmen@gmail.com>
 *                    Victor Thompson <victor.thompson@gmail.com>
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
     contentsHeight: parent.height;

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
             musicToolbar.disableToolbar()
             musicToolbar.setSheet(addtoPlaylist)
         }
         else
         {
             musicToolbar.enableToolbar()
             musicToolbar.removeSheet(addtoPlaylist)
         }
     }

     Rectangle {
         width: parent.width

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
                    height: units.gu(8)
                    property string name: model.name
                    property string count: model.count
                    property string cover0: model.cover0 || ""
                    property string cover1: model.cover1 || ""
                    property string cover2: model.cover2 || ""
                    property string cover3: model.cover3 || ""
                    onClicked: {
                        console.debug("Debug: "+chosenTrack+" added to "+name)
                        Playlists.addtoPlaylist(name,chosenTrack,chosenArtist,chosenTitle,chosenAlbum,chosenCover,"","","","")
                        var count = Playlists.getPlaylistCount(name) // get the new count
                        playlistModel.model.set(index, {"count": count}) // update number ot tracks in playlist
                        onDoneClicked: PopupUtils.close(addtoPlaylist)
                    }

                    CoverRow {
                        id: coverRow
                        anchors {
                            top: parent.top
                            left: parent.left
                            margins: units.gu(1)
                        }
                        count: parseInt(playlist.count)
                        size: units.gu(6)
                        covers: [playlist.cover0, playlist.cover1, playlist.cover2, playlist.cover3]
                    }

                    Label {
                        id: playlistName
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            leftMargin: units.gu(11)
                            topMargin: units.gu(2)
                            bottomMargin: units.gu(4)
                        }
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                        fontSize: "medium"
                        elide: Text.ElideRight
                        text: playlist.name + " ("+playlist.count+")"
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
             anchors.top: addtoPlaylistView.bottom
             anchors.topMargin: units.gu(5)
             onClicked: {
                 customdebug("New playlist.")
                 PopupUtils.open(newPlaylistDialog, mainView)
             }
         }

     }
 }
