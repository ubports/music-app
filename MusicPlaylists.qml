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

    // function that adds each playlist in the listmodel to show it in the app
    function addtoPlaylistModel(element,index,array) {
        customdebug("Playlist #" + element.id + " = " + element.name);
        playlistModel.append({"id": element.id, "name": element.name, "count": element.count});
    }

    // Toolbar
    ToolbarItems {
        id: playlistToolbar
        // Add playlist
        ToolbarButton {
            id: playlistAction
            objectName: "playlistaction"
            iconSource: Qt.resolvedUrl("images/add.svg")
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
                console.debug('Debug: Show settings from Playlists')
                PopupUtils.open(Qt.resolvedUrl("MusicSettings.qml"), mainView,
                                {
                                    title: i18n.tr("Settings")
                                } )
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
        playlist.forEach(addtoPlaylistModel) // send each item on playlist array to the model to show it
    }

    MusicSettings {
        id: musicSettings
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
                       property string name: model.name
                       property string count: model.count
                       iconFrame: false

                       UbuntuShape {
                           id: cover0
                           anchors.right: cover1.left
                           width: units.gu(6)
                           height: parent.height
                           color: get_random_color()
                           x: 0
                           z: 1
                       }
                       UbuntuShape {
                           id: cover1
                           anchors.left: cover0.right
                           width: units.gu(6)
                           height: parent.height
                           color: get_random_color()
                           x: 50
                           z: 2
                       }
                       UbuntuShape {
                           id: cover2
                           anchors.left: cover1.right
                           width: units.gu(6)
                           height: parent.height
                           color: get_random_color()
                           x: 50
                           z: 3
                       }
                       UbuntuShape {
                           id: cover3
                           anchors.left: cover2.right
                           width: units.gu(6)
                           height: parent.height
                           color: get_random_color()
                           x: 50
                           z: 4
                       }

                       Label {
                           id: playlistName
                           wrapMode: Text.NoWrap
                           maximumLineCount: 1
                           fontSize: "medium"
                           anchors.left: cover3.right
                           anchors.leftMargin: units.gu(2)
                           anchors.top: parent.top
                           anchors.topMargin: 5
                           anchors.bottomMargin: 5
                           anchors.right: parent.right
                           text: playlist.name + " ("+playlist.count+")"
                       }

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
        tools: playlistToolbar
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
            state: "normal"
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

            property int normalHeight: units.gu(6.5)
            property string playlistName: ""
            property int transitionDuration: 250

            Component {
                id: playlisttrackDelegate
                ListItem.Standard {
                    id: playlistTracks
                    height: playlistlist.normalHeight

                    SwipeDelete {
                        id: swipeBackground
                        duration: playlistlist.transitionDuration

                        onDeleteStateChanged: {
                            if (deleteState === true)
                            {
                                console.debug("Remove from playlist: " + playlistlist.playlistName + " file: " + file);

                                var realID = Playlists.getRealID(playlistlist.playlistName, index);
                                Playlists.removeFromPlaylist(playlistlist.playlistName, realID);

                                playlistlist.model.remove(index);
                                queueChanged = true;
                            }
                        }
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
                            customdebug("File: " + file) // debugger
                            trackClicked(playlisttracksModel, index) // play track
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
                                // Remove if moved > 10 units otherwise reset
                                if (Math.abs(playlistTracks.x - startX) > units.gu(10))
                                {
                                    /*
                                     * Remove the listitem
                                     *
                                     * Remove the listitem to relevant side (playlistTracksRemoveAnimation)
                                     * Reduce height of listitem and remove the item
                                     *   (swipeDeleteAnimation [called on playlistTracksRemoveAnimation complete])
                                     */
                                    swipeBackground.runSwipeDeletePrepareAnimation();  // fade out the clear text
                                    playlistTracksRemoveAnimation.start();  // remove item from listview
                                }
                                else
                                {
                                    /*
                                     * Reset the listitem
                                     *
                                     * Remove the swipeDelete to relevant side (swipeResetAnimation)
                                     * Reset the listitem to the centre (playlistTracksResetAnimation)
                                     */
                                    playlistTracksResetAnimation.start();  // reset item position
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

                        /*
                         * Animation to remove an item from the list
                         * - Removes listitem to relevant side
                         * - Calls swipeDeleteAnimation to delete the listitem
                         */
                        NumberAnimation {
                            id: playlistTracksRemoveAnimation
                            target: playlistTracks
                            property: "x"
                            to: swipeBackground.state == "swipingRight" ? playlistTracks.width : 0 - playlistTracks.width
                            duration: playlistlist.transitionDuration

                            onRunningChanged: {
                                // Remove from queue once animation has finished
                                if (running == false)
                                {
                                    swipeBackground.runSwipeDeleteAnimation();
                                }
                            }
                        }
                    }
                    Rectangle {
                        id: trackContainer;
                        anchors.fill: parent
                        anchors.margins: units.gu(0.5)
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
                            id: trackImage
                            anchors.left: parent.left
                            anchors.leftMargin: units.gu(2)
                            anchors.top: parent.top
                            anchors.verticalCenter: parent.verticalCenter
                            height: parent.height
                            width: height
                            image: Image {
                                source: cover !== "" ? cover :  Qt.resolvedUrl("images/cover_default_icon.png")
                            }
                            UbuntuShape {  // Background so can see text in current state
                                id: trackBg
                                anchors.top: parent.top
                                color: styleMusic.common.black
                                height: units.gu(6)
                                opacity: 0
                                width: parent.width
                            }
                        }

                        Label {
                            id: trackTitle
                            anchors.top: parent.top
                            anchors.topMargin: units.gu(0.5)
                            color: styleMusic.common.white
                            elide: Text.ElideRight
                            height: units.gu(1)
                            text: title == "" ? file : title
                            width: parent.width
                            x: trackImage.x + trackImage.width + units.gu(1)
                        }
                        Label {
                            id: trackArtistAlbum
                            anchors.top: trackTitle.bottom
                            anchors.topMargin: units.gu(1)
                            color: styleMusic.nowPlaying.labelSecondaryColor
                            elide: Text.ElideRight
                            text: artist == "" ? "" : artist + " - " + album
                            width: parent.width
                            x: trackImage.x + trackImage.width + units.gu(1)
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

        tools: playlistToolbar
    }
}
