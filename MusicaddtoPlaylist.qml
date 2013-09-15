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
 DefaultSheet {
     id: addtoPlaylist
     title: i18n.tr("Select playlist")

     onDoneClicked: PopupUtils.close(addtoPlaylist)

     Component.onCompleted:  {
         // check the four latest track in each playlist
         // get the cover art of them
         // print them in the icon
     }

     Column {
         spacing: units.gu(2)

         // show each playlist and make them chosable
         ListView {
             id: addtoPlaylistView
             width: parent.width
             height: units.gu(30)
             model: playlistModel
             delegate: ListItem.Standard {
                    text: name +" ("+count+")"
                    icon: Qt.resolvedUrl("images/playlist.png")
                    iconFrame: false
                    height: units.gu(6)
                    width: units.gu(48)
                    onClicked: {
                        console.debug("Debug: "+chosenTrack+" added to "+name)
                        Playlists.addtoPlaylist(name,chosenTrack,chosenArtist,chosenTitle,chosenAlbum)
                        var count = Playlists.getPlaylistCount(name) // get the new count
                        playlistModel.set(index, {"count": count}) // update number ot tracks in playlist
                        onDoneClicked: PopupUtils.close(addtoPlaylist)
                    }
             }
         }

         Button {
             id: newPlaylistItem
             text: i18n.tr("New playlist")
             anchors.top: addtoPlaylistView.bottom
             width: units.gu(48)
             iconSource: "images/add.svg"
             iconPosition: "left"
             onClicked: {
                 customdebug("New playlist.")
                 PopupUtils.open(newPlaylistDialog, mainView)
             }
         }
    }
 }
