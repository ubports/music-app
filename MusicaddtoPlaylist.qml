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

// Page that will be used when adding tracks to playlists
 Page {
     id: addtoPlaylist
     title: i18n.tr("Select playlist")
     anchors.fill: parent
     visible: false

     onVisibleChanged: {
         if (visible === true)
         {
             header.hide();
             header.visible = false;
         }
         else
         {
             header.visible = true;
             header.show();
         }
     }

     Rectangle {
         anchors.fill: parent
         color: styleMusic.addtoPlaylist.backgroundColor
         MouseArea {  // Block events to lower layers
             anchors.fill: parent
         }
     }

     // show each playlist and make them chosable
     ListView {
         id: addtoPlaylistView
         width: parent.width
         height: units.gu(35)
         model: playlistModel
         delegate: ListItem.Standard {
                text: name +" ("+count+")"
                onClicked: {
                    console.debug("Debug: "+chosenTrack+" added to "+name)
                    Playlists.addtoPlaylist(name,chosenTrack,chosenArtist,chosenTitle,chosenAlbum,chosenCover,"","","","")
                    var count = Playlists.getPlaylistCount(name)
                    playlistModel.setProperty(chosenIndex, "count", count) // update number ot tracks in playlist
                    playerControls.visible = true // show the playercontrols again
                    addtoPlaylist.visible = false // back to previous page
                }
         }
     }

     Button {
         id: newPlaylistItem
         text: i18n.tr("New playlist")
         anchors.top: addtoPlaylistView.bottom
         width: parent.width - units.gu(4)
         iconSource: "images/add.svg"
         iconPosition: "left"
         onClicked: {
             customdebug("New playlist.")
             PopupUtils.open(newPlaylistDialog, mainView)
         }
     }

     Rectangle {
         id: cancelButton
         anchors.bottom: parent.bottom
         height: units.gu(8)
         width: parent.width
         color: styleMusic.playerControls.backgroundColor
         Button {
             text: i18n.tr("Cancel")
             anchors.margins: units.gu(2)
             onClicked: {
                 playerControls.visible = true // show the playercontrols again
                 addtoPlaylist.visible = false // back to previous page
                 // send notification
             }
         }
     }
 }
