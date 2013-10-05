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
     }

     Rectangle {
         width: parent.width

         // show each playlist and make them chosable
         ListView {
             id: addtoPlaylistView
             width: parent.width
             height: parent.width
             model: playlistModel
             delegate: ListItem.Standard {
                    id: playlist
                    //text: name +" ("+count+")"
                    property string name: model.name
                    property string count: model.count
                    iconFrame: false
                    onClicked: {
                        console.debug("Debug: "+chosenTrack+" added to "+name)
                        Playlists.addtoPlaylist(name,chosenTrack,chosenArtist,chosenTitle,chosenAlbum,chosenCover,"","","","")
                        var count = Playlists.getPlaylistCount(name) // get the new count
                        playlistModel.set(index, {"count": count}) // update number ot tracks in playlist
                        onDoneClicked: PopupUtils.close(addtoPlaylist)
                    }
                    UbuntuShape {
                        id: cover0
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(4)
                        width: units.gu(6)
                        height: parent.height
                        color: get_random_color()
                        visible: playlist.count > 3
                    }
                    UbuntuShape {
                        id: cover1
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(3)
                        width: units.gu(6)
                        height: parent.height
                        color: get_random_color()
                        visible: playlist.count > 2
                    }
                    UbuntuShape {
                        id: cover2
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(2)
                        width: units.gu(6)
                        height: parent.height
                        color: get_random_color()
                        visible: playlist.count > 1
                    }
                    UbuntuShape {
                        id: cover3
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(1)
                        width: units.gu(6)
                        height: parent.height
                        color: get_random_color()
                    }
                    Label {
                        id: playlistName
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                        fontSize: "medium"
                        anchors.left: cover3.right
                        anchors.leftMargin: units.gu(4)
                        anchors.top: parent.top
                        anchors.topMargin: 5
                        anchors.bottomMargin: 5
                        anchors.right: parent.right
                        text: playlist.name + " ("+playlist.count+")"
                        color: styleMusic.addtoPlaylist.labelColor
                    }
             }
         }

         Button {
             id: newPlaylistItem
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
