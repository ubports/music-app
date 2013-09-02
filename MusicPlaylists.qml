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
import org.nemomobile.folderlistmodel 1.0
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

    // function that adds each playlist in the listmodel to show it in the app
    function addtoPlaylistModel(element,index,array) {
        customdebug("Playlist #" + index + " = " + element);
        playlistModel.append({"id": element.id, "name": element.name, "count": element.count});
    }

    // Remove playlist dialog
    Component {
         id: removePlaylistDialog
         Dialog {
             id: dialogueRemovePlaylist
             title: i18n.tr("Are you sure?")
             text: i18n.tr("This will delete your playlist.")

             Button {
                 text: i18n.tr("Remove")
                 onClicked: {
                     // removing playlist
                     Playlists.removePlaylist(oldPlaylistID, oldPlaylistName) // remove using both ID and name, if playlists has similair names
                     playlistModel.remove(oldPlaylistIndex)
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

    // Edit name of playlist dialog
    Component {
         id: editPlaylistDialog
         Dialog {
             id: dialogueEditPlaylist
             title: i18n.tr("Change name")
             text: i18n.tr("Enter the new name of the playlist.")
             TextField {
                 id: playlistName
                 placeholderText: oldPlaylistName
             }
             ListItem.Standard {
                 id: newplaylistoutput
             }

             Button {
                 text: i18n.tr("Change")
                 onClicked: {
                     if (playlistName.text.length > 0) { // make sure something is acually inputed
                         var editList = Playlists.namechangePlaylist(oldPlaylistName,playlistName.text) // change the name of the playlist in DB
                         console.debug("Debug: User changed name from "+oldPlaylistName+" to "+playlistName.text)
                         playlistModel.set(oldPlaylistIndex, {"name": playlistName.text})
                         PopupUtils.close(dialogueEditPlaylist)
                     }
                     else {
                        newplaylistoutput.text = i18n.tr("You didn't type in a name.")
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

    // Popover to change name and remove playlists
    Component {
        id: playlistPopoverComponent
        Popover {
            id: playlistPopover
            Column {
                id: containerLayout
                anchors {
                    left: parent.left
                    top: parent.top
                    right: parent.right
                }
                ListItem.Standard {
                    Label {
                        text: i18n.tr("Change name")
                        color: styleMusic.popover.labelColor
                        fontSize: "large"
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    onClicked: {
                        console.debug("Debug: Change name of playlist.")
                        PopupUtils.open(editPlaylistDialog, mainView)
                        PopupUtils.close(playlistPopover)
                    }
                }
                ListItem.Standard {
                    Label {
                        text: i18n.tr("Remove")
                        color: styleMusic.popover.labelColor
                        fontSize: "large"
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    onClicked: {
                        console.debug("Debug: Remove playlist.")
                        PopupUtils.open(removePlaylistDialog, mainView)
                        PopupUtils.close(playlistPopover)
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        pageStack.push(listspage)

        random = Settings.getSetting("shuffle") == "1" // shuffle state
        scrobble = Settings.getSetting("scrobble") == "1" // scrobble state
        lastfmusername = Settings.getSetting("lastfmusername") // lastfm username
        lastfmpassword = Settings.getSetting("lastfmpassword") // lastfm password

        // get playlists in an array
        var playlist = Playlists.getPlaylists(); // get the playlist from the database
        // add the alternatives to the ListModel
        var length = playlist.length,
            element = null;
        for (var i = 0; i < length; i++) {
            element = playlist[i];
            customdebug("Playlist: #"+element.id+" "+element.name+" with number of tracks: "+element.count)
            playlistModel.append({"id": element.id, "name": element.name, "count": element.count});
        }
    }

    // page for the playlists
    Page {
        id: listspage
        title: i18n.tr("Playlists")
        ListView {
            id: playlistslist
            width: parent.width
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.bottomMargin: units.gu(8)
            model: playlistModel
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
                    icon: Qt.resolvedUrl("images/playlist.png")
                    iconFrame: false
                    text: name+" ("+count+")"

                    onPressAndHold: {
                        customdebug("Pressed and held playlist "+name+" : "+index)
                        // show a dialog to change name and remove list
                        oldPlaylistName = name
                        oldPlaylistID = id
                        oldPlaylistIndex = index
                        PopupUtils.open(playlistPopoverComponent, mainView)
                    }

                    onClicked: {
                        customdebug("Playlist chosen: " + name)
                        playlisttracksModel.filterPlaylistTracks(name)
                        playlistlist.playlistName = name
                        pageStack.push(playlistpage) // show the chosen playlists content
                        playlistpage.title = name + " " + "("+ count +")" // change name of the tab
                    }
                }
            }
        }

        tools: ToolbarItems {
            // import playlist from lastfm
            ToolbarButton {
                objectName: "lastfmplaylistaction"

                iconSource: Qt.resolvedUrl("images/lastfm.png")
                text: i18n.tr("Import")
                visible: false // only show if scobble is activated

                onTriggered: {
                    console.debug("Debug: User pressed action to import playlist from lastfm")
                    Scrobble.getPlaylists(Settings.getSetting("lastfmusername"))
                }
            }

            // Add playlist
            ToolbarButton {
                id: playlistAction
                objectName: "playlistaction"
                iconSource: Qt.resolvedUrl("images/playlist.png")
                text: i18n.tr("New")
                onTriggered: {
                    console.debug("Debug: User pressed add playlist")
                    // show new playlist dialog
                    PopupUtils.open(newPlaylistDialog, mainView)
                }
            }

            // Settings dialog
            ToolbarButton {
                objectName: "settingsaction"
                iconSource: Qt.resolvedUrl("images/settings.png")
                text: i18n.tr("Settings")

                onTriggered: {
                    console.debug('Debug: Show settings')
                    PopupUtils.open(Qt.resolvedUrl("MusicSettings.qml"), mainView,
                                    {
                                        title: i18n.tr("Settings")
                                    } )
                }
            }
        }
    }

    // page for the tracks in the playlist
    Page {
        id: playlistpage
        title: i18n.tr("Playlist")

        Component.onCompleted: {
            onPlayingTrackChange.connect(updateHighlightPlaylist)
        }

        function updateHighlightPlaylist(file)
        {
            console.debug("MusicPlaylist update highlight:", file)
            playlistlist.currentIndex = playlisttracksModel.indexOf(file)
        }

        ListView {
            id: playlistlist
            width: parent.width
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.bottomMargin: units.gu(8)
            highlightFollowsCurrentItem: false
            model: playlisttracksModel.model
            delegate: playlisttrackDelegate
            onCountChanged: {
                console.log("Tracks in playlist onCountChanged: " + playlistlist.count)
                playlistlist.currentIndex = playlisttracksModel.indexOf(currentFile)
            }
            onCurrentIndexChanged: {
                console.log("Tracks in playlist tracklist.currentIndex = " + playlistlist.currentIndex)
            }

            property string playlistName: null

            Component {
                id: playlisttrackDelegate
                ListItem.Standard {
                    id: playlistTracks
                    icon: Library.hasCover(file) ? "image://cover-art/"+file : Qt.resolvedUrl("images/cover_default_icon.png")
                    iconFrame: false
                    removable: true

                    backgroundIndicator: SwipeDelete {
                        id: swipeDelete
                        state: swipingState
                        property string text: i18n.tr("Clear")
                    }

                    onFocusChanged: {
                        if (focus == false) {
                            selected = false
                        } else {
                            selected = false
                        }
                    }
                    onItemRemoved: {
                        console.debug("Remove from playlist: " + playlistlist.playlistName + " file: " + file);
                        Playlists.removeFromPlaylist(playlistlist.playlistName, file);
                    }

                    /* Do not use mousearea otherwise swipe delete won't function */
                    onClicked: {
                        customdebug("File: " + file) // debugger
                        trackClicked(playlisttracksModel, index) // play track
                        nowPlaying.visible = true // show the queue
                    }
                    onPressAndHold: {
                        customdebug("Pressed and held track playlist "+file)
                        //PopupUtils.open(playlistPopoverComponent, mainView)
                    }

                    Label {
                        id: trackTitle
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                        fontSize: "medium"
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(8)
                        anchors.top: parent.top
                        anchors.topMargin: 5
                        anchors.right: parent.right
                        text: title == "" ? file : title
                    }
                    Label {
                        id: trackArtistAlbum
                        wrapMode: Text.NoWrap
                        maximumLineCount: 2
                        fontSize: "small"
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(8)
                        anchors.top: trackTitle.bottom
                        anchors.right: parent.right
                        text: artist == "" ? "" : artist + " - " + album
                    }
                    Rectangle {
                        id: highlight
                        anchors.left: parent.left
                        visible: false
                        width: units.gu(.75)
                        height: parent.height
                        color: styleMusic.listView.highlightColor;
                    }
                    states: State {
                        name: "Current"
                        when: playlistTracks.ListView.isCurrentItem
                        PropertyChanges { target: highlight; visible: true }
                    }
                }
            }
        }
    }
}
