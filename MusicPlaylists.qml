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
import "playing-list.js" as PlayingList
import "playlists.js" as Playlists

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
        playlistModel.append({"id": index, "name": element});
    }

    // function that adds each track from playlist in the listmodel to show it in the app
    function addtoPlaylistTracksModel(element,index,array) {
        customdebug("Track #" + index + " = " + element);
        var arry = element.split(',');
        playlisttracksModel.model.append({"id": index, "file": arry[0], "artist": arry[1], "title": arry[2], "album": arry[3] });
    }

    // New playlist dialog
    Component {
         id: newPlaylistDialog
         Dialog {
             id: dialogueNewPlaylist
             title: i18n.tr("New Playlist")
             text: i18n.tr("Name your playlist.")
             TextField {
                 id: playlistName
                 placeholderText: i18n.tr("Name")
             }
             ListItem.Standard {
                 id: newplaylistoutput
             }

             Button {
                 text: i18n.tr("Create")
                 onClicked: {
                     if (playlistName.text.length > 0) { // make sure something is acually inputed
                         var newList = Playlists.addPlaylist(playlistName.text)
                         if (newList === "OK") {
                             console.debug("Debug: User created a new playlist named: "+playlistName.text)
                             // add the new playlist to the tab
                             var index = Playlists.getID(); // get the latest ID
                             playlistModel.append({"id": index, "name": playlistName.text})
                         }
                         else {
                             console.debug("Debug: Something went wrong: "+newList)
                         }

                         PopupUtils.close(dialogueNewPlaylist)
                     }
                     else {
                        newplaylistoutput.text = i18n.tr("You didn't type in a name.")

                     }
                }
             }

             Button {
                 text: i18n.tr("Cancel")
                 color: styleMusic.dialog.buttonColor
                 onClicked: PopupUtils.close(dialogueNewPlaylist)
             }
         }
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
             text: i18n.tr("Enter the new playlist name")
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
        pageStack.push(playlistspage)

        random = Settings.getSetting("shuffle") == "1" // shuffle state
        scrobble = Settings.getSetting("scrobble") == "1" // scrobble state
        lastfmusername = Settings.getSetting("lastfmusername") // lastfm username
        lastfmpassword = Settings.getSetting("lastfmpassword") // lastfm password

        // first add queue
        playlistModel.append({"id": 0, "name": i18n.tr("Queue")});

        // get playlists in an array
        var playlist = Playlists.getPlaylists(); // get the playlist from the database
        customdebug("Playlists: "+playlist) //debug
        playlist.forEach(addtoPlaylistModel) // send each item on playlist array to the model to show it
    }

    // page for the playlists
    Page {
        id: playlistspage
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
            onModelChanged: {
                customdebug("PlayingList cleared")
            }

            Component {
                id: playlistDelegate
                ListItem.Subtitled {
                    id: playlist
                    icon: Qt.resolvedUrl("images/playlist.png")
                    iconFrame: false
                    text: name
                    subText: i18n.tr("With "+ playlist.count + " tracks")

                    MouseArea {
                        anchors.fill: parent
                        onDoubleClicked: {
                        }

                        onPressAndHold: {
                            customdebug("Pressed and held playlist "+name+" : "+index)

                            // queue is not the same thing as a playlist, so do this
                            if (name === i18n.tr("Queue")) {
                                customdebug("User tried to change name of queue, but no go!")
                            }
                            else {
                                // show a dialog to change name and remove list
                                oldPlaylistName = name
                                oldPlaylistID = id
                                oldPlaylistIndex = index
                                PopupUtils.open(playlistPopoverComponent, mainView)
                            }

                        }

                        onClicked: {
                            // queue is not the same thing as a playlist, so do this
                            if (name === i18n.tr("Queue")) {
                                customdebug("User clicked Queue.")
                                pageStack.push(queuepage)
                            }
                            else {
                                customdebug("Playlist chosen: " + name)
                                // get tracks in playlists in array
                                var playlistTracks = Playlists.getPlaylistTracks(name) // get array of tracks
                                playlistTracks.forEach(addtoPlaylistTracksModel) // send each item in playlist array to the model to show it
                                pageStack.push(playlistpage)
                            }
                        }
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
                visible: false

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
        title: i18n.tr("Tracks in Playlist")

        Component.onCompleted: {
            onPlayingTrackChange.connect(updateHighlightPlaylist)
        }

        function updateHighlightPlaylist(file)
        {
            console.debug("MusicPlaylist update highlight:", file)
            playlistlist.currentIndex = playlisttracksModel.indexOf(file)
        }

        Component {
            id: highlightPlaylist
            Rectangle {
                width: units.gu(.75)
                color: "#FFFFFF";
                Behavior on y {
                    SpringAnimation {
                        spring: 3
                        damping: 0.2
                    }
                }
            }
        }

        ListView {
            id: playlistlist
            width: parent.width
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.bottomMargin: units.gu(8)
            highlight: highlightPlaylist
            highlightFollowsCurrentItem: true
            model: playlisttracksModel.model
            delegate: playlisttrackDelegate
            onCountChanged: {
                console.log("Tracks in playlist onCountChanged: " + playlistlist.count)
                playlistlist.currentIndex = playlisttracksModel.indexOf(currentFile)
            }
            onCurrentIndexChanged: {
                console.log("Tracks in playlist tracklist.currentIndex = " + playlistlist.currentIndex)
            }
            onModelChanged: {
                console.log("PlayingList cleared")
            }

            Component {
                id: playlisttrackDelegate
                ListItem.Subtitled {
                    id: playlistTracks
                    icon: Qt.resolvedUrl("images/cover_default.png") // fix!
                    iconFrame: false
                    text: title
                    subText: artist+" - "+album

                    onFocusChanged: {
                        if (focus == false) {
                            selected = false
                        } else {
                            selected = false
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onDoubleClicked: {
                        }
                        onPressAndHold: {
                            customdebug("Pressed and held track playlist "+name)
                            //PopupUtils.open(playlistPopoverComponent, mainView)
                        }
                        onClicked: {
                            customdebug("Track: " + file) // debugger
                            trackClicked(file, index, playlisttracksModel.model, playlistlist) // play track
                        }
                    }
                }
            }
        }
    }

    // Page for Queue
    Page {
        id: queuepage
        title: i18n.tr("Queue")

        Component.onCompleted: {
            onPlayingTrackChange.connect(updateHighlightQueue)
        }

        function updateHighlightQueue(file)
        {
            customdebug("MusicQueue update highlight: " + file)
            queuelist.currentIndex = trackQueue.indexOf(file)
        }

        Component {
            id: highlightQueue
            Rectangle {
                width: units.gu(.75)
                color: "#FFFFFF";
                Behavior on y {
                    SpringAnimation {
                        spring: 3
                        damping: 0.2
                    }
                }
            }
        }

        ListView {
            id: queuelist
            width: parent.width
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.bottomMargin: units.gu(8)
            highlight: highlightQueue
            highlightFollowsCurrentItem: true
            model: trackQueue.model
            delegate: queueDelegate
            onCountChanged: {
                customdebug("Queue: Now has: " + queuelist.count + " tracks")
            }

            Component {
                id: queueDelegate
                ListItem.Subtitled {
                    id: playlistTracks
                    icon: Qt.resolvedUrl("images/queue.png") // fix!
                    iconFrame: false
                    text: title
                    subText: artist+" - "+album

                    onFocusChanged: {
                        if (focus == false) {
                            selected = false
                        } else {
                            selected = false
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onDoubleClicked: {
                        }
                        onPressAndHold: {
                            customdebug("Pressed and held queued track "+name)
                        }
                        onClicked: {
                            customdebug("Track: " + file) // debugger
                            trackClicked(file, index, trackQueue.model, queuelist) // play track
                        }

                        /*onItemRemoved: {
                            trackQueue.remove(index)
                        }*/
                    }
                }
            }
        }

        tools: ToolbarItems {
            // Clean queue button
            ToolbarButton {
                objectName: "clearqueueobject"

                iconSource: Qt.resolvedUrl("images/clear.png")
                text: i18n.tr("Clear")

                onTriggered: {
                    console.debug("Debug: Track queue cleared.")
                    trackQueue.model.clear()
                }
            }
        }
    }
}
