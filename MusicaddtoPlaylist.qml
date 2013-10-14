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

     onVisibleChanged: {
         if (visible === true)
         {
             musicToolbar.disableToolbar()
         }
         else
         {
             musicToolbar.enableToolbar()
         }
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
                        playlistModel.set(index, {"count": count}) // update number ot tracks in playlist
                        onDoneClicked: PopupUtils.close(addtoPlaylist)
                    }
                    UbuntuShape {
                        id: cover0
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(4)
                        anchors.top: parent.top
                        anchors.topMargin: units.gu(1)
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: units.gu(1)
                        width: units.gu(6)
                        visible: playlist.count > 3
                        image: Image {
                            source: playlist.cover3 !== "" ? playlist.cover3 :  Qt.resolvedUrl("images/cover_default_icon.png")
                        }
                    }
                    UbuntuShape {
                        id: cover1
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(3)
                        anchors.top: parent.top
                        anchors.topMargin: units.gu(1)
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: units.gu(1)
                        width: units.gu(6)
                        visible: playlist.count > 2
                        image: Image {
                            source: playlist.cover2 !== "" ? playlist.cover2 :  Qt.resolvedUrl("images/cover_default_icon.png")
                        }
                    }
                    UbuntuShape {
                        id: cover2
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(2)
                        anchors.top: parent.top
                        anchors.topMargin: units.gu(1)
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: units.gu(1)
                        width: units.gu(6)
                        visible: playlist.count > 1
                        image: Image {
                            source: playlist.cover1 !== "" ? playlist.cover1 :  Qt.resolvedUrl("images/cover_default_icon.png")
                        }
                    }
                    UbuntuShape {
                        id: cover3
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(1)
                        anchors.top: parent.top
                        anchors.topMargin: units.gu(1)
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: units.gu(1)
                        width: units.gu(6)
                        image: Image {
                            source: playlist.cover0 !== "" ? playlist.cover0 :  Qt.resolvedUrl("images/cover_default_icon.png")
                        }
                    }
                    Label {
                        id: playlistName
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                        fontSize: "medium"
                        anchors.left: cover3.right
                        anchors.leftMargin: units.gu(4)
                        anchors.top: parent.top
                        anchors.topMargin: units.gu(2)
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: units.gu(4)
                        anchors.right: parent.right
                        elide: Text.ElideRight
                        text: playlist.name + " ("+playlist.count+")"
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
