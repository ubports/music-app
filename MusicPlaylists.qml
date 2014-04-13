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

// page for the playlists
Page {
    id: listspage
    // TRANSLATORS: this is the name of the playlists page shown in the tab header.
    // Remember to keep the translation short to fit the screen width
    title: i18n.tr("Playlists")

    property string playlistTracks: ""
    property string oldPlaylistName: ""
    property string oldPlaylistIndex: ""
    property string oldPlaylistID: ""
    property string inPlaylist: ""

    onVisibleChanged: {
        if (visible === true)
        {
            musicToolbar.setPage(listspage);
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
                }
            }
            Button {
                text: i18n.tr("Cancel")
                color: styleMusic.dialog.buttonColor
                onClicked: PopupUtils.close(dialogueRemovePlaylist)
            }
        }
    }

    MusicSettings {
        id: musicSettings
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
                property var covers: Playlists.getPlaylistCovers(name)
                iconFrame: false
                height: styleMusic.playlist.playlistItemHeight

                CoverRow {
                    id: coverRow
                    anchors {
                        top: parent.top
                        left: parent.left
                        margins: units.gu(1)
                    }
                    count: playlist.covers.length
                    size: styleMusic.playlist.playlistAlbumSize
                    covers: playlist.covers
                }

                // songs count
                Label {
                    id: playlistCount
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: expandItem.left
                        topMargin: units.gu(2)
                        leftMargin: units.gu(12)
                        rightMargin: units.gu(1.5)
                    }
                    elide: Text.ElideRight
                    fontSize: "x-small"
                    color: styleMusic.common.subtitle
                    height: units.gu(1)
                    text: i18n.tr("%1 song", "%1 songs", playlist.count).arg(playlist.count)
                }
                // playlist name
                Label {
                    id: playlistName
                    anchors {
                        top: playlistCount.bottom
                        left: playlistCount.left
                        right: expandItem.left
                        topMargin: units.gu(1)
                        rightMargin: units.gu(1.5)
                    }
                    wrapMode: Text.NoWrap
                    maximumLineCount: 1
                    fontSize: "medium"
                    color: styleMusic.common.music
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
                    albumTracksModel.filterPlaylistTracks(name)
                    songsSheet.isAlbum = false
                    songsSheet.line1 = "Playlist"
                    songsSheet.line2 = model.name
                    songsSheet.covers =  playlist.covers
                    PopupUtils.open(songsSheet.sheet)
                }
            }
        }
    }
}
