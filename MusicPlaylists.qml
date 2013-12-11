/*
 * Copyright (C) 2013 Daniel Holm <d.holmen@gmail.com>
                      Victor Thompson <victor.thompson@gmail.com>
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

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1
import Ubuntu.Components.Popups 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import "settings.js" as Settings
import "meta-database.js" as Library
import "scrobble.js" as Scrobble
import "playlists.js" as Playlists
import "common"

PageStack {
    id: pageStack
    anchors.fill: parent

    property string playlistTracks: ""
    property string oldPlaylistName: ""
    property string oldPlaylistIndex: ""
    property string oldPlaylistID: ""
    property string inPlaylist: ""

    // Remove playlist dialog
    Component {
         id: removePlaylistDialog
         Dialog {
             id: dialogueRemovePlaylist
             // TRANSLATORS: this is a title of a dialog with a prompt to delete a playlist
             title: i18n.tr("Are you sure?")
             text: i18n.tr("This will delete your playlist.")

             Button {
                 text: i18n.tr("Remove")
                 onClicked: {
                     // removing playlist
                     Playlists.removePlaylist(oldPlaylistID, oldPlaylistName) // remove using both ID and name, if playlists has similair names
                     playlistModel.model.remove(oldPlaylistIndex)
                     PopupUtils.close(dialogueRemovePlaylist)
                     if (inPlaylist) {
                         customdebug("Back to playlists")
                         pageStack.pop()
                     }
                }
             }
             Button {
                 text: i18n.tr("Cancel")
                 color: styleMusic.dialog.buttonColor
                 onClicked: PopupUtils.close(dialogueRemovePlaylist)
             }
         }
    }

    // Edit name of playlist dialog
    Component {
         id: editPlaylistDialog
         Dialog {
             id: dialogueEditPlaylist
             // TRANSLATORS: this is a title of a dialog with a prompt to rename a playlist
             title: i18n.tr("Change name")
             text: i18n.tr("Enter the new name of the playlist.")
             TextField {
                 id: playlistName
                 placeholderText: oldPlaylistName
             }
             ListItem.Standard {
                 id: editplaylistoutput
                 visible: false
             }

             Button {
                 text: i18n.tr("Change")
                 onClicked: {
                     editplaylistoutput.visible = true
                     if (playlistName.text.length > 0) { // make sure something is acually inputed
                         var editList = Playlists.namechangePlaylist(oldPlaylistName,playlistName.text) // change the name of the playlist in DB
                         console.debug("Debug: User changed name from "+oldPlaylistName+" to "+playlistName.text)
                         playlistModel.model.set(oldPlaylistIndex, {"name": playlistName.text})
                         PopupUtils.close(dialogueEditPlaylist)
                         if (inPlaylist) {
                             playlistInfoLabel.text = playlistName.text
                         }
                     }
                     else {
                        editplaylistoutput.text = i18n.tr("You didn't type in a name.")
                     }
                }
             }
             Button {
                 text: i18n.tr("Cancel")
                 color: styleMusic.dialog.buttonColor
                 onClicked: PopupUtils.close(dialogueEditPlaylist)
             }
         }
    }

    Component.onCompleted: {
        pageStack.push(listspage)
        // fix pageStack bug the ugly way
        pageStack.push(playlistpage)
        pageStack.pop()

        random = Settings.getSetting("shuffle") == "1" // shuffle state
        scrobble = Settings.getSetting("scrobble") == "1" // scrobble state
        lastfmusername = Settings.getSetting("lastfmusername") // lastfm username
        lastfmpassword = Settings.getSetting("lastfmpassword") // lastfm password
    }

    MusicSettings {
        id: musicSettings
    }

    // page for the playlists
    Page {
        id: listspage
        // TRANSLATORS: this is the name of the playlists page shown in the tab header.
        // Remember to keep the translation short to fit the screen width
        title: i18n.tr("Playlists")

        onVisibleChanged: {
            if (visible === true)
            {
                musicToolbar.setPage(listspage);
            }
        }

        ListView {
            id: playlistslist
            objectName: "playlistslist"
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
                ListItem.Standard {
                       id: playlist
                       property string name: model.name
                       property string count: model.count
                       property string cover0: model.cover0 || ""
                       property string cover1: model.cover1 || ""
                       property string cover2: model.cover2 || ""
                       property string cover3: model.cover3 || ""
                       iconFrame: false
                       height: styleMusic.playlist.playlistItemHeight

                       UbuntuShape {
                           id: cover0
                           anchors.left: parent.left
                           anchors.leftMargin: units.gu(4)
                           anchors.top: parent.top
                           anchors.topMargin: units.gu(1)
                           height: styleMusic.playlist.playlistAlbumSize
                           width: styleMusic.playlist.playlistAlbumSize
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
                           height: styleMusic.playlist.playlistAlbumSize
                           width: styleMusic.playlist.playlistAlbumSize
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
                           height: styleMusic.playlist.playlistAlbumSize
                           width: styleMusic.playlist.playlistAlbumSize
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
                           height: styleMusic.playlist.playlistAlbumSize
                           width: styleMusic.playlist.playlistAlbumSize
                           image: Image {
                               source: playlist.cover0 !== "" ? playlist.cover0 :  Qt.resolvedUrl("images/cover_default_icon.png")
                           }
                       }
                       // songs count
                       Label {
                           id: playlistCount
                           anchors.left: cover3.right
                           anchors.leftMargin: units.gu(4)
                           anchors.top: parent.top
                           anchors.topMargin: units.gu(2)
                           anchors.right: expandItem.left
                           anchors.rightMargin: units.gu(1.5)
                           elide: Text.ElideRight
                           fontSize: "x-small"
                           height: units.gu(1)
                           text: i18n.tr("%1 song", "%1 songs", playlist.count).arg(playlist.count)
                       }
                       // playlist name
                       Label {
                           id: playlistName
                           wrapMode: Text.NoWrap
                           maximumLineCount: 1
                           fontSize: "medium"
                           color: styleMusic.common.music
                           anchors.left: cover3.right
                           anchors.leftMargin: units.gu(4)
                           anchors.top: playlistCount.bottom
                           anchors.topMargin: units.gu(1)
                           anchors.right: expandItem.left
                           anchors.rightMargin: units.gu(1.5)
                           elide: Text.ElideRight
                           text: playlist.name
                       }

                       //Icon {
                       Image {
                           id: expandItem
                         //  name: "dropdown-menu"
                           source: expandable.visible ? "images/dropdown-menu-up.svg" : "images/dropdown-menu.svg"
                           anchors.right: parent.right
                           anchors.rightMargin: units.gu(2)
                           height: styleMusic.common.expandedItem
                           width: styleMusic.common.expandedItem
                           y: parent.y + (styleMusic.playlist.playlistItemHeight / 2) - (height / 2)
                       }

                       MouseArea {
                           anchors.bottom: parent.bottom
                           anchors.right: parent.right
                           anchors.top: parent.top
                           width: styleMusic.common.expandedItem * 3
                           onClicked: {
                              if(expandable.visible) {
                                  customdebug("clicked collapse")
                                  expandable.visible = false
                                  playlist.height = styleMusic.playlist.playlistItemHeight
                              }
                              else {
                                  customdebug("clicked expand")
                                  collapseExpand(-1);  // collapse all others
                                  expandable.visible = true
                                  playlist.height = styleMusic.playlists.expandedHeight
                              }
                           }
                       }

                       Rectangle {
                           id: expandable
                           anchors.fill: parent
                           color: "transparent"
                           height: styleMusic.common.expandHeight
                           visible: false

                           Component.onCompleted: {
                               collapseExpand.connect(onCollapseExpand);
                           }

                           function onCollapseExpand(indexCol)
                           {
                               if ((indexCol === index || indexCol === -1) && expandable !== undefined && expandable.visible === true)
                               {
                                   customdebug("auto collapse")
                                   expandable.visible = false
                                   playlist.height = styleMusic.playlist.playlistItemHeight
                               }
                           }

                           // background for expander
                           Rectangle {
                               anchors.top: parent.top
                               anchors.topMargin: styleMusic.playlist.playlistItemHeight
                               color: styleMusic.common.black
                               height: styleMusic.playlists.expandedHeight - styleMusic.playlist.playlistItemHeight
                               width: playlist.width
                               opacity: 0.4
                           }

                           Rectangle {
                               id: editColumn
                               anchors.top: parent.top
                               anchors.topMargin: ((styleMusic.playlists.expandedHeight - styleMusic.playlist.playlistItemHeight) / 2)
                                                  + styleMusic.playlist.playlistItemHeight
                                                  - (height / 2)
                               anchors.left: parent.left
                               anchors.leftMargin: styleMusic.common.expandedLeftMargin
                               height: styleMusic.common.expandedItem
                               Rectangle {
                                   color: "transparent"
                                   height: styleMusic.common.expandedItem
                                   width: units.gu(15)
                                   Icon {
                                       id: editPlaylist
                                       color: styleMusic.common.white
                                       name: "edit"
                                       height: styleMusic.common.expandedItem
                                       width: styleMusic.common.expandedItem
                                   }
                                   Label {
                                       anchors.left: editPlaylist.right
                                       anchors.leftMargin: units.gu(0.5)
                                       color: styleMusic.common.white
                                       fontSize: "small"
                                       // TRANSLATORS: this refers to editing a playlist
                                       text: i18n.tr("Edit")
                                   }
                                   MouseArea {
                                      anchors.fill: parent
                                      onClicked: {
                                          expandable.visible = false
                                          playlist.height = styleMusic.playlist.playlistItemHeight
                                          customdebug("Edit playlist")
                                          oldPlaylistName = name
                                          oldPlaylistID = id
                                          oldPlaylistIndex = index
                                          PopupUtils.open(editPlaylistDialog, mainView)
                                      }
                                   }
                                }
                           }

                           Rectangle {
                               id: deleteColumn
                               anchors.top: parent.top
                               anchors.topMargin: ((styleMusic.playlists.expandedHeight - styleMusic.playlist.playlistItemHeight) / 2)
                                                  + styleMusic.playlist.playlistItemHeight
                                                  - (height / 2)
                               anchors.horizontalCenter: parent.horizontalCenter
                               height: styleMusic.common.expandedItem
                               Rectangle {
                                   color: "transparent"
                                   height: styleMusic.common.expandedItem
                                   width: units.gu(15)
                                   Icon {
                                       id: deletePlaylist
                                       color: styleMusic.common.white
                                       name: "delete"
                                       height: styleMusic.common.expandedItem
                                       width: styleMusic.common.expandedItem
                                   }
                                   Label {
                                       anchors.left: deletePlaylist.right
                                       anchors.leftMargin: units.gu(0.5)
                                       color: styleMusic.common.white
                                       fontSize: "small"
                                       // TRANSLATORS: this refers to deleting a playlist
                                       text: i18n.tr("Delete")
                                   }
                                   MouseArea {
                                      anchors.fill: parent
                                      onClicked: {
                                          expandable.visible = false
                                          playlist.height = styleMusic.playlist.playlistItemHeight
                                          customdebug("Delete")
                                          oldPlaylistName = name
                                          oldPlaylistID = id
                                          oldPlaylistIndex = index
                                          PopupUtils.open(removePlaylistDialog, mainView)
                                      }
                                   }
                                }
                            }
                           // share
                           Rectangle {
                               id: shareColumn
                               anchors.top: parent.top
                               anchors.topMargin: ((styleMusic.playlists.expandedHeight - styleMusic.playlist.playlistItemHeight) / 2)
                                                  + styleMusic.playlist.playlistItemHeight
                                                  - (height / 2)
                               anchors.left: deleteColumn.right
                               anchors.leftMargin: units.gu(2)
                               anchors.right: parent.right
                               visible: false
                               Rectangle {
                                   color: "transparent"
                                   height: styleMusic.common.expandedItem
                                   width: units.gu(15)
                                   Icon {
                                       id: sharePlaylist
                                       color: styleMusic.common.white
                                       name: "share"
                                       height: styleMusic.common.expandedItem
                                       width: styleMusic.common.expandedItem
                                   }
                                   Label {
                                       anchors.left: sharePlaylist.right
                                       anchors.leftMargin: units.gu(0.5)
                                       color: styleMusic.common.white
                                       fontSize: "small"
                                       // TRANSLATORS: this refers to sharing a playlist
                                       text: i18n.tr("Share")
                                   }
                                   MouseArea {
                                      anchors.fill: parent
                                      onClicked: {
                                          expandable.visible = false
                                          playlist.height = styleMusic.playlist.playlistItemHeight
                                          customdebug("Share")
                                          inPlaylist = true
                                      }
                                   }
                                }
                            }
                       }

                    onClicked: {
                        customdebug("Playlist chosen: " + name)
                        expandable.visible = false
                        playlist.height = styleMusic.playlist.playlistItemHeight
                        playlisttracksModel.filterPlaylistTracks(name)
                        playlistlist.playlistName = name
                        pageStack.push(playlistpage) // show the chosen playlists content
                        playlistpage.title = name + " " + "("+ count +")" // change name of the tab
                        // for removal or edit in playlist
                        oldPlaylistName = name
                        oldPlaylistID = id
                        oldPlaylistIndex = index
                        expandable.visible = false
                        playlistInfo.count = playlist.count
                        playlistInfo.cover0 = playlist.cover0
                        playlistInfo.cover1 = playlist.cover1
                        playlistInfo.cover2 = playlist.cover2
                        playlistInfo.cover3 = playlist.cover3
                    }
                }
            }
        }
    }

    // page for the tracks in the playlist
    Page {
        id: playlistpage
        title: i18n.tr("Playlist")
        tools: null
        visible: false

        onVisibleChanged: {
            if (visible === true)
            {
                musicToolbar.setPage(playlistpage, listspage, pageStack);
            }
            else
            {
                collapseSwipeDelete(-1);  // collapse all expands
            }
        }

        // playlist name and info
        Rectangle {
            id: playlistInfo
            anchors.top: parent.top
            width: parent.width
            height: styleMusic.playlist.infoHeight
            color: styleMusic.playerControls.backgroundColor
            //opacity: 0.7

            property int count: 0
            property string cover0: ""
            property string cover1: ""
            property string cover2: ""
            property string cover3: ""

            UbuntuShape {
                id: cover0
                anchors.left: parent.left
                anchors.leftMargin: units.gu(5)
                anchors.top: parent.top
                anchors.topMargin: units.gu(2)
                width: styleMusic.common.albumSize
                height: styleMusic.common.albumSize
                visible: playlistInfo.count > 3
                image: Image {
                    source: playlistInfo.cover3 !== "" ? playlistInfo.cover3 : Qt.resolvedUrl("images/cover_default_icon.png")
                }
            }
            UbuntuShape {
                id: cover1
                anchors.left: parent.left
                anchors.leftMargin: units.gu(4)
                anchors.top: parent.top
                anchors.topMargin: units.gu(2)
                width: styleMusic.common.albumSize
                height: styleMusic.common.albumSize
                visible: playlistInfo.count > 2
                image: Image {
                    source: playlistInfo.cover2 !== "" ? playlistInfo.cover2 :  Qt.resolvedUrl("images/cover_default_icon.png")
                }
            }
            UbuntuShape {
                id: cover2
                anchors.left: parent.left
                anchors.leftMargin: units.gu(3)
                anchors.top: parent.top
                anchors.topMargin: units.gu(2)
                width: styleMusic.common.albumSize
                height: styleMusic.common.albumSize
                visible: playlistInfo.count > 1
                image: Image {
                    source: playlistInfo.cover1 !== "" ? playlistInfo.cover1 :  Qt.resolvedUrl("images/cover_default_icon.png")
                }
            }
            UbuntuShape {
                id: cover3
                anchors.left: parent.left
                anchors.leftMargin: units.gu(2)
                anchors.top: parent.top
                anchors.topMargin: units.gu(2)
                width: styleMusic.common.albumSize
                height: styleMusic.common.albumSize
                image: Image {
                    source: playlistInfo.cover0 !== "" ? playlistInfo.cover0 :  Qt.resolvedUrl("images/cover_default_icon.png")
                }
            }

            Label {
                id: playlistInfoLabel
                text: playlistlist.playlistName
                color: styleMusic.common.white
                fontSize: "large"
                anchors.left: parent.left
                anchors.leftMargin: units.gu(16)
                anchors.top: parent.top
                anchors.topMargin: units.gu(2.5)
                anchors.right: expandInfoItem.left
                anchors.rightMargin: units.gu(1.5)
                elide: Text.ElideRight
            }

            Label {
                id: playlistInfoCount
                text: i18n.tr("%1 song", "%1 songs", playlist.count).arg(playlist.count)
                color: styleMusic.common.white
                fontSize: "medium"
                anchors.left: parent.left
                anchors.leftMargin: units.gu(16)
                anchors.top: parent.top
                anchors.topMargin: units.gu(5)
                anchors.right: expandInfoItem.left
                anchors.rightMargin: units.gu(1.5)
                elide: Text.ElideRight
            }

            //Icon { use for 1.0
            Image {
                id: expandInfoItem
                anchors.right: parent.right
                anchors.rightMargin: units.gu(2)
                //name: "dropdown-menu" use for 1.0
                source: expandableInfo.visible ? "images/dropdown-menu-up.svg" : "images/dropdown-menu.svg"
                height: styleMusic.common.expandedItem
                width: styleMusic.common.expandedItem
                y: parent.y + (styleMusic.playlist.infoHeight / 2) - (height / 2)
            }

            MouseArea {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.top: parent.top
                width: styleMusic.common.expandedItem * 3
                onClicked: {
                   if(expandableInfo.visible) {
                       customdebug("clicked collapse")
                       expandableInfo.visible = false
                       playlistInfo.height = styleMusic.playlist.infoHeight

                   }
                   else {
                       customdebug("clicked expand")
                       expandableInfo.visible = true
                       playlistInfo.height = styleMusic.playlist.expandedHeight
                   }
               }
           }

            Rectangle {
                id: expandableInfo
                anchors.fill: parent
                color: "transparent"
                height: styleMusic.common.expandHeight
                visible: false
                Rectangle {
                    id: editColumn
                    anchors.top: parent.top
                    anchors.topMargin: styleMusic.common.expandedTopMargin
                    anchors.left: parent.left
                    anchors.leftMargin: styleMusic.common.expandedLeftMargin
                    color: "transparent"
                    Rectangle {
                        id: editRow
                        color: "transparent"
                        height: styleMusic.common.expandedItem
                        width: units.gu(15)
                        Icon {
                            id: editPlaylist
                            name: "edit"
                            height: styleMusic.common.expandedItem
                            width: styleMusic.common.expandedItem
                        }
                        Label {
                            text: i18n.tr("Edit")
                            fontSize: "small"
                            wrapMode: Text.WordWrap
                            anchors.left: editPlaylist.right
                            anchors.leftMargin: units.gu(0.5)
                        }
                        MouseArea {
                           anchors.fill: parent
                           onClicked: {
                               expandableInfo.visible = false
                               playlistInfo.height = styleMusic.playlist.infoHeight
                               customdebug("Edit playlist")
                               inPlaylist = true
                               PopupUtils.open(editPlaylistDialog, mainView)
                         }
                       }
                    }
                }

                Rectangle {
                    id: deleteColumn
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: styleMusic.common.expandedTopMargin
                    color: "transparent"
                    Rectangle {
                        id: deleteRow
                        color: "transparent"
                        height: styleMusic.common.expandedItem
                        width: units.gu(15)
                        Icon {
                            id: deletePlaylist
                            name: "delete"
                            height: styleMusic.common.expandedItem
                            width: styleMusic.common.expandedItem
                        }
                        Label {
                            text: i18n.tr("Delete")
                            fontSize: "small"
                            anchors.left: deletePlaylist.right
                            anchors.leftMargin: units.gu(0.5)
                        }
                        MouseArea {
                           anchors.fill: parent
                           onClicked: {
                               expandableInfo.visible = false
                               playlistInfo.height = styleMusic.playlist.infoHeight
                               customdebug("Delete")
                               inPlaylist = true
                               PopupUtils.open(removePlaylistDialog, mainView)
                         }
                       }
                    }
                 }
                // share
                Rectangle {
                    id: shareColumn
                    anchors.top: parent.top
                    anchors.topMargin: styleMusic.common.expandedTopMargin
                    anchors.left: deleteColumn.right
                    anchors.leftMargin: units.gu(2)
                    anchors.right: parent.right
                    color: "transparent"
                    visible: false
                    Rectangle {
                        id: shareRow
                        color: "transparent"
                        height: styleMusic.common.expandedItem
                        width: units.gu(15)
                        Icon {
                            id: sharePlaylist
                            name: "share"
                            height: styleMusic.common.expandedItem
                            width: styleMusic.common.expandedItem
                        }
                        Label {
                            text: i18n.tr("Share")
                            fontSize: "small"
                            anchors.left: sharePlaylist.right
                            anchors.leftMargin: units.gu(0.5)
                        }
                        MouseArea {
                           anchors.fill: parent
                           onClicked: {
                               expandableInfo.visible = false
                               playlistInfo.height = styleMusic.playlist.infoHeight
                               customdebug("Share")
                               inPlaylist = true
                         }
                       }
                    }
                 }
            }
        }

        ListView {
            id: playlistlist
            anchors.bottom: parent.bottom
            anchors.top: playlistInfo.bottom
            width: parent.width
            anchors.bottomMargin: musicToolbar.mouseAreaOffset + musicToolbar.minimizedHeight
            highlightFollowsCurrentItem: false
            model: playlisttracksModel.model
            delegate: playlisttrackDelegate
            state: "normal"
            z: -1
            states: [
                State {
                    name: "normal"
                    PropertyChanges {
                        target: playlistlist
                        interactive: true
                    }
                },
                State {
                    name: "reorder"
                    PropertyChanges {
                        target: playlistlist
                        interactive: false
                    }
                }
            ]

            onCountChanged: {
                console.log("Tracks in playlist onCountChanged: " + playlistlist.count)
                playlistlist.currentIndex = playlisttracksModel.indexOf(currentFile)
            }
            onCurrentIndexChanged: {
                console.log("Tracks in playlist tracklist.currentIndex = " + playlistlist.currentIndex)
            }

            property int normalHeight: styleMusic.common.itemHeight
            property string playlistName: ""
            property int transitionDuration: 250

            Component {
                id: playlisttrackDelegate
                ListItem.Standard {
                    id: playlistTracks
                    property string artist: model.artist
                    property string album: model.album
                    property string title: model.title
                    property string cover: model.cover
                    property string length: model.length
                    property string file: model.file
                    height: playlistlist.normalHeight

                    SwipeDelete {
                        id: swipeBackground
                        duration: playlistlist.transitionDuration

                        onDeleteStateChanged: {
                            if (deleteState === true)
                            {
                                playlistTracksRemoveAnimation.start();
                            }
                        }
                    }

                    function onCollapseSwipeDelete(indexCol)
                    {
                        if ((indexCol !== index || indexCol === -1) && swipeBackground !== undefined && swipeBackground.direction !== "")
                        {
                            customdebug("auto collapse swipeDelete")
                            playlistTracksResetStartAnimation.start();
                        }
                    }

                    Component.onCompleted: {
                        collapseSwipeDelete.connect(onCollapseSwipeDelete);
                    }

                    MouseArea {
                        id: playlistTrackArea
                        anchors.fill: parent

                        property int startX: playlistTracks.x
                        property int startY: playlistTracks.y
                        property int startMouseY: -1

                        // Allow dragging on the X axis for swipeDelete if not reordering
                        drag.target: playlistTracks
                        drag.axis: Drag.XAxis
                        drag.minimumX: playlistlist.state == "reorder" ? 0 : -playlistTracks.width
                        drag.maximumX: playlistlist.state == "reorder" ? 0 : playlistTracks.width

                        /* Get the mouse and item difference from the starting positions */
                        function getDiff(mouseY)
                        {
                            return (mouseY - startMouseY) + (playlistTracks.y - startY);
                        }

                        function getNewIndex(mouseY, index)
                        {
                            var diff = getDiff(mouseY);
                            var negPos = diff < 0 ? -1 : 1;

                            return index + (Math.round(diff / playlistlist.normalHeight));
                        }

                        onClicked: {
                            collapseSwipeDelete(-1);  // collapse all expands
                            customdebug("File: " + file) // debugger
                            trackClicked(playlisttracksModel, index) // play track
                            Library.addRecent(oldPlaylistName, "Playlist", cover, oldPlaylistName, "playlist")
                            mainView.hasRecent = true
                            recentModel.filterRecent()
                        }

                        onMouseXChanged: {
                            // Only allow XChange if not in reorder state
                            if (playlistlist.state == "reorder")
                            {
                                return;
                            }

                            // New X is less than start so swiping left
                            if (playlistTracks.x < startX)
                            {
                                swipeBackground.state = "swipingLeft";
                            }
                            // New X is greater sow swiping right
                            else if (playlistTracks.x > startX)
                            {
                                swipeBackground.state = "swipingRight";
                            }
                            // Same so reset state back to normal
                            else
                            {
                                swipeBackground.state = "normal";
                                playlistlist.state = "normal";
                            }
                        }

                        onMouseYChanged: {
                            // Y change only affects when in reorder mode
                            if (playlistlist.state == "reorder")
                            {
                                /* update the listitem y position so that the
                                 * listitem horizontalCenter is under the mouse.y */
                                playlistTracks.y += mouse.y - (playlistTracks.height / 2);
                            }
                        }

                        onPressed: {
                            startX = playlistTracks.x;
                            startY = playlistTracks.y;
                            startMouseY = mouse.y;
                        }

                        onPressAndHold: {
                            collapseSwipeDelete(-1);  // collapse all expands
                            customdebug("Pressed and held track playlist "+file)
                            playlistlist.state = "reorder";  // enable reordering state
                            trackContainerReorderAnimation.start();
                            //PopupUtils.open(playlistPopoverComponent, mainView)
                        }

                        onReleased: {
                            // Get current state to determine what to do
                            if (playlistlist.state == "reorder")
                            {
                                var newIndex = getNewIndex(mouse.y + (playlistTracks.height / 2), index);  // get new index

                                // Indexes larger than current need -1 because when it is moved the current is removed
                                if (newIndex > index)
                                {
                                    newIndex -= 1;
                                }

                                if (newIndex === index)
                                {
                                    playlistTracksResetAnimation.start();  // reset item position
                                    trackContainerResetAnimation.start();  // reset the trackContainer
                                }
                                else
                                {
                                    playlistTracks.x = startX;  // ensure X position is correct
                                    trackContainerResetAnimation.start();  // reset the trackContainer

                                    // Check that the newIndex is within the range
                                    if (newIndex < 0)
                                    {
                                        newIndex = 0;
                                    }
                                    else if (newIndex > playlistlist.count - 1)
                                    {
                                        newIndex = playlistlist.count - 1;
                                    }

                                    console.debug("Move: " + index + " To: " + newIndex);

                                    // get the real IDs and update the database
                                    var realID = Playlists.getRealID(playlistlist.playlistName, index);
                                    var realNewID = Playlists.getRealID(playlistlist.playlistName, newIndex);
                                    Playlists.move(playlistlist.playlistName, realID, realNewID);

                                    playlistlist.model.move(index, newIndex, 1);  // update the model
                                    queueChanged = true;
                                }
                            }
                            else if (swipeBackground.state == "swipingLeft" || swipeBackground.state == "swipingRight")
                            {
                                var moved = Math.abs(playlistTracks.x - startX);

                                // Make sure that item has been dragged far enough
                                if (moved > playlistTracks.width / 2 || (swipeBackground.primed === true && moved > units.gu(5)))
                                {
                                    if (swipeBackground.primed === false)
                                    {
                                        collapseSwipeDelete(index);  // collapse other swipeDeletes

                                        // Move the listitem half way across to reveal the delete button
                                        playlistTracksPrepareRemoveAnimation.start();
                                    }
                                    else
                                    {
                                        // Check that actually swiping to cancel
                                        if (swipeBackground.direction !== "" &&
                                                swipeBackground.direction !== swipeBackground.state)
                                        {
                                            // Reset the listitem to the centre
                                            playlistTracksResetStartAnimation.start();
                                        }
                                        else
                                        {
                                            // Reset the listitem to the centre
                                            playlistTracksResetAnimation.start();
                                        }
                                    }
                                }
                                else
                                {
                                    // Reset the listitem to the centre
                                    playlistTracksResetAnimation.start();
                                }
                            }

                            // ensure states are normal
                            swipeBackground.state = "normal";
                            playlistlist.state = "normal";
                        }

                        // Animation to reset the x, y of the item
                        ParallelAnimation {
                            id: playlistTracksResetAnimation
                            running: false
                            NumberAnimation {  // reset X
                                target: playlistTracks
                                property: "x"
                                to: playlistTrackArea.startX
                                duration: playlistlist.transitionDuration
                            }
                            NumberAnimation {  // reset Y
                                target: playlistTracks
                                property: "y"
                                to: playlistTrackArea.startY
                                duration: playlistlist.transitionDuration
                            }
                        }

                        // Animation to reset the x, y of the item
                        ParallelAnimation {
                            id: playlistTracksResetStartAnimation
                            running: false
                            NumberAnimation {  // reset X
                                target: playlistTracks
                                property: "x"
                                to: 0
                                duration: playlistlist.transitionDuration
                            }
                            NumberAnimation {  // reset Y
                                target: playlistTracks
                                property: "y"
                                to: playlistTrackArea.startY
                                duration: playlistlist.transitionDuration
                            }
                            onRunningChanged: {
                                if (running === true)
                                {
                                    swipeBackground.direction = "";
                                    swipeBackground.primed = false;
                                }
                            }
                        }

                        // Move the listitem half way across to reveal the delete button
                        NumberAnimation {
                            id: playlistTracksPrepareRemoveAnimation
                            target: playlistTracks
                            property: "x"
                            to: swipeBackground.state == "swipingRight" ? playlistTracks.width / 2 : 0 - (playlistTracks.width / 2)
                            duration: playlistlist.transitionDuration
                            onRunningChanged: {
                                if (running === true)
                                {
                                    swipeBackground.direction = swipeBackground.state;
                                    swipeBackground.primed = true;
                                }
                            }
                        }

                        ParallelAnimation {
                            id: playlistTracksRemoveAnimation
                            running: false
                            NumberAnimation {  // 'slide' up
                                target: playlistTracks
                                property: "height"
                                to: 0
                                duration: playlistlist.transitionDuration
                            }
                            NumberAnimation {  // 'slide' in direction of removal
                                target: playlistTracks
                                property: "x"
                                to: swipeBackground.direction === "swipingLeft" ? 0 - playlistTracks.width : playlistTracks.width
                                duration: playlistlist.transitionDuration
                            }
                            onRunningChanged: {
                                if (running === false)
                                {
                                    console.debug("Remove from playlist: " + playlistlist.playlistName + " file: " + file);

                                    var realID = Playlists.getRealID(playlistlist.playlistName, index);
                                    Playlists.removeFromPlaylist(playlistlist.playlistName, realID);

                                    playlistlist.model.remove(index);
                                    playlistModel.model.get(oldPlaylistIndex).count -= 1;
                                    queueChanged = true;
                                }
                            }
                        }
                    }
                    Rectangle {
                        id: trackContainer;
                        anchors.fill: parent
                        anchors.margins: units.gu(1)
                        color: "transparent"

                        NumberAnimation {
                            id: trackContainerReorderAnimation
                            target: trackContainer;
                            property: "anchors.leftMargin";
                            duration: playlistlist.transitionDuration;
                            to: units.gu(2)
                        }

                        NumberAnimation {
                            id: trackContainerResetAnimation
                            target: trackContainer;
                            property: "anchors.leftMargin";
                            duration: playlistlist.transitionDuration;
                            to: units.gu(0.5)
                        }

                        UbuntuShape {
                            id: trackCover
                            anchors.left: parent.left
                            anchors.leftMargin: units.gu(1)
                            anchors.top: parent.top
                            anchors.verticalCenter: parent.verticalCenter
                            width: styleMusic.common.albumSize
                            height: styleMusic.common.albumSize
                            image: Image {
                                source: cover !== "" ? cover :  Qt.resolvedUrl("images/cover_default_icon.png")
                            }
                            UbuntuShape {  // Background so can see text in current state
                                id: trackBg
                                anchors.top: parent.top
                                color: styleMusic.common.black
                                width: styleMusic.common.albumSize
                                height: styleMusic.common.albumSize
                                opacity: 0
                            }
                        }

                        Label {
                            id: trackArtist
                            wrapMode: Text.NoWrap
                            maximumLineCount: 2
                            fontSize: "x-small"
                            anchors.left: trackCover.left
                            anchors.leftMargin: units.gu(11)
                            anchors.top: parent.top
                            anchors.topMargin: units.gu(1)
                            anchors.right: parent.right
                            anchors.rightMargin: units.gu(1.5)
                            elide: Text.ElideRight
                            text: playlistTracks.artist == "" ? "" : playlistTracks.artist
                        }
                        Label {
                            id: trackTitle
                            wrapMode: Text.NoWrap
                            maximumLineCount: 1
                            fontSize: "small"
                            color: styleMusic.common.music
                            anchors.left: trackCover.left
                            anchors.leftMargin: units.gu(11)
                            anchors.top: trackArtist.bottom
                            anchors.topMargin: units.gu(1)
                            anchors.right: parent.right
                            anchors.rightMargin: units.gu(1.5)
                            elide: Text.ElideRight
                            text: playlistTracks.title == "" ? playlistTracks.file : playlistTracks.title
                        }
                        Label {
                            id: trackAlbum
                            wrapMode: Text.NoWrap
                            maximumLineCount: 2
                            fontSize: "xx-small"
                            anchors.left: trackCover.left
                            anchors.leftMargin: units.gu(11)
                            anchors.top: trackTitle.bottom
                            anchors.topMargin: units.gu(2)
                            anchors.right: parent.right
                            anchors.rightMargin: units.gu(1.5)
                            elide: Text.ElideRight
                            text: playlistTracks.album
                        }
                        Label {
                            id: trackDuration
                            wrapMode: Text.NoWrap
                            maximumLineCount: 2
                            fontSize: "small"
                            color: styleMusic.common.music
                            anchors.left: trackCover.left
                            anchors.leftMargin: units.gu(12)
                            anchors.top: trackAlbum.bottom
                            anchors.right: parent.right
                            anchors.rightMargin: units.gu(1.5)
                            elide: Text.ElideRight
                            visible: false
                            text: ""
                        }
                        states: State {
                            name: "Current"
                            when: playlistTracks.ListView.isCurrentItem
                        }
                        Image {
                            visible: false // activate when cover art stops expanding togehter with the row
                            id: expandItem
                            anchors.right: parent.right
                            anchors.rightMargin: units.gu(2)
                            anchors.top: parent.top
                            anchors.topMargin: units.gu(4)
                            source: "images/select.png"
                            height: styleMusic.common.expandedItem
                            width: styleMusic.common.expandedItem

                            MouseArea {
                               anchors.fill: parent
                               onClicked: {
                                   if(expandable.visible) {
                                       customdebug("clicked collapse")
                                       expandable.visible = false
                                       playlistTracks.height = styleMusic.common.itemHeight

                                   }
                                   else {
                                       customdebug("clicked expand")
                                       expandable.visible = true
                                       playlistTracks.height = styleMusic.common.expandedHeight
                                   }
                               }
                           }
                        }

                        Rectangle {
                            id: expandable
                            visible: false
                            width: parent.fill
                            height: styleMusic.common.expandHeight
                            MouseArea {
                               anchors.fill: parent
                               onClicked: {
                                   customdebug("User pressed outside the playlist item and expanded items.")
                             }
                           }
                        }
                    }
                }
            }
        }
    }
}
