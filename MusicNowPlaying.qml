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
import QtQuick.LocalStorage 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.Popups 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import "common"
import "meta-database.js" as Library
import "settings.js" as Settings

Page {
    id: nowPlaying
    anchors.fill: parent
    title: i18n.tr("Queue")
    visible: false

    onVisibleChanged: {
        if (visible === true)
        {
            header.hide();
            header.visible = false;
            header.opacity = 0;
            musicToolbar.setPage(nowPlaying, musicToolbar.currentPage);
        }
        else
        {
            header.visible = true;
            header.opacity = 1;
            header.show();
        }
    }

    property int ensureVisibleIndex: -1

    Rectangle {
        anchors.fill: parent
        color: styleMusic.nowPlaying.backgroundColor
        opacity: 0.9 // change later
        MouseArea {  // Block events to lower layers
            anchors.fill: parent
        }
    }

    Component.onCompleted: {
        onPlayingTrackChange.connect(updateCurrentIndex)
        onToolbarShownChanged.connect(jumpToCurrent)
    }

    function jumpToCurrent(shown, currentPage, currentTab)
    {
        // If the toolbar is shown, the page is now playing and snaptrack is enabled
        if (shown && currentPage === nowPlaying && Settings.getSetting("snaptrack") === "1")
        {
            // Then position the view at the current index
            queuelist.positionViewAtIndex(queuelist.currentIndex, ListView.Contain);
        }
    }

    function updateCurrentIndex(file)
    {
        customdebug("MusicQueue update currentIndex: " + file)
        queuelist.currentIndex = trackQueue.indexOf(file)
    }

    ListView {
        id: queuelist
        anchors.fill: parent
        anchors.bottomMargin: musicToolbar.mouseAreaOffset + musicToolbar.minimizedHeight
        anchors.topMargin: nowPlayingBackButton.height
        delegate: queueDelegate
        model: trackQueue.model
        highlightFollowsCurrentItem: false
        state: "normal"
        states: [
            State {
                name: "normal"
                PropertyChanges {
                    target: queuelist
                    interactive: true
                }
            },
            State {
                name: "reorder"
                PropertyChanges {
                    target: queuelist
                    interactive: false
                }
            }
        ]

        property int currentHeight: units.gu(40)
        property int normalHeight: units.gu(6.5)
        property int transitionDuration: 250  // transition length of animations

        onCountChanged: {
            customdebug("Queue: Now has: " + queuelist.count + " tracks")
        }

        Component {
            id: queueDelegate
            ListItem.Standard {
                id: queueListItem
                height: queuelist.normalHeight
                state: queuelist.currentIndex == index ? "current" : ""

                SwipeDelete {
                    id: swipeBackground
                    duration: queuelist.transitionDuration

                    onDeleteStateChanged: {
                        if (deleteState === true)
                        {
                            // Remove the item
                            if (index == queuelist.currentIndex)
                            {
                                if (queuelist.count > 1)
                                {
                                    // Next song and only play if currently playing
                                    nextSong(isPlaying);
                                }
                                else
                                {
                                    stopSong();
                                }
                            }

                            // Remove item from queue and clear caches
                            queueChanged = true;
                            trackQueue.model.remove(index);
                            currentIndex = trackQueue.indexOf(currentFile);  // recalculate index

                            // undo
                            console.debug("removed :"+index+title+artist+album+file)
                            undoRemoval("trackQueue.model",index,title,artist,album,file)
                        }
                    }
                }

                MouseArea {
                    id: queueArea
                    anchors.fill: parent

                    property int startX: queueListItem.x
                    property int startY: queueListItem.y
                    property int startMouseY: -1

                    // Allow dragging on the X axis for swipeDelete if not reordering
                    drag.target: queueListItem
                    drag.axis: Drag.XAxis
                    drag.minimumX: queuelist.state == "reorder" ? 0 : -queueListItem.width
                    drag.maximumX: queuelist.state == "reorder" ? 0 : queueListItem.width

                    /* Get the mouse and item difference from the starting positions */
                    function getDiff(mouseY)
                    {
                        return (mouseY - startMouseY) + (queueListItem.y - startY);
                    }

                    /*
                     * Has the mouse crossed the current item
                     * True - it has crossed
                     * NULL - it is on the current
                     * False - it has not crossed
                     */
                    function hasCrossedCurrent(diff, currentOffset)
                    {
                        // Only crossed if in same direction
                        if ((diff > 0 || currentOffset > 0) && (diff <= 0 || currentOffset <= 0))
                        {
                            return false;
                        }

                        if (Math.abs(diff) > (Math.abs(currentOffset) * queuelist.normalHeight) + queuelist.currentHeight)
                        {
                            return true;
                        }
                        else if (Math.abs(diff) > (Math.abs(currentOffset) * queuelist.normalHeight))
                        {
                            return null;
                        }
                        else
                        {
                            return false;
                        }
                    }

                    function getNewIndex(mouseY, index)
                    {
                        var diff = getDiff(mouseY);
                        var negPos = diff < 0 ? -1 : 1;
                        var currentOffset = queuelist.currentIndex - index;  // get the current offset

                        if (currentOffset < 0)  // when current is less the offset is actually +1
                        {
                            currentOffset += 1;
                        }

                        var hasCrossed = hasCrossedCurrent(diff, currentOffset);

                        if (hasCrossed === true)
                        {
                            /* Take off difference so it just appears like a normalheight
                             * minus when after and add when before */
                            diff -= negPos * (queuelist.currentHeight - queuelist.normalHeight);
                        }
                        else if (hasCrossed === null)
                        {
                            // Work out how far into the current item it is
                            var tmpDiff = Math.abs(diff) - (Math.abs(currentOffset) * queuelist.normalHeight);

                            // Scale difference so is the same as a normalHeight
                            tmpDiff *= (queuelist.normalHeight / queuelist.currentHeight);

                            // rebuild Diff with new values
                            diff = (currentOffset * queuelist.normalHeight) + (negPos * tmpDiff);
                        }

                        return index + (Math.round(diff / queuelist.normalHeight));
                    }

                    onClicked: {
                        customdebug("File: " + file) // debugger
                        trackClicked(trackQueue, index) // play track
                    }

                    onMouseXChanged: {
                        // Only allow XChange if not in reorder state
                        if (queuelist.state == "reorder")
                        {
                            return;
                        }

                        // New X is less than start so swiping left
                        if (queueListItem.x < startX)
                        {
                            swipeBackground.state = "swipingLeft";
                        }
                        // New X is greater sow swiping right
                        else if (queueListItem.x > startX)
                        {
                            swipeBackground.state = "swipingRight";
                        }
                        // Same so reset state back to normal
                        else
                        {
                            swipeBackground.state = "normal";
                            queuelist.state = "normal";
                        }
                    }

                    onMouseYChanged: {
                        // Y change only affects when in reorder mode
                        if (queuelist.state == "reorder")
                        {
                            /* update the listitem y position so that the
                             * listitem horizontalCenter is under the mouse.y */
                            queueListItem.y += mouse.y - (queueListItem.height / 2);
                        }
                    }

                    onPressed: {
                        startX = queueListItem.x;
                        startY = queueListItem.y;
                        startMouseY = mouse.y;
                    }

                    onPressAndHold: {
                        // Must be in a normal state to change to reorder state
                        if (queuelist.state == "normal" && swipeBackground.state == "normal" && queuelist.currentIndex != index)
                        {
                            customdebug("Pressed and held queued track "+file)
                            queuelist.state = "reorder";  // enable reordering state
                            trackContainerReorderAnimation.start();
                        }
                    }

                    onReleased: {
                        // Get current state to determine what to do
                        if (queuelist.state == "reorder")
                        {
                            var newIndex = getNewIndex(mouse.y + (queueListItem.height / 2), index);  // get new index

                            // Indexes larger than current need -1 because when it is moved the current is removed
                            if (newIndex > index)
                            {
                                newIndex -= 1;
                            }

                            if (newIndex === index)
                            {
                                queueListItemResetAnimation.start();  // reset item position
                                trackContainerResetAnimation.start();  // reset the trackContainer
                            }
                            else
                            {
                                queueListItem.x = startX;  // ensure X position is correct
                                trackContainerResetAnimation.start();  // reset the trackContainer

                                // Check that the newIndex is within the range
                                if (newIndex < 0)
                                {
                                    newIndex = 0;
                                }
                                else if (newIndex > queuelist.count - 1)
                                {
                                    newIndex = queuelist.count - 1;
                                }

                                console.debug("Move: " + index + " To: " + newIndex);
                                queuelist.model.move(index, newIndex, 1);  // update the model
                            }
                        }
                        else if (swipeBackground.state == "swipingLeft" || swipeBackground.state == "swipingRight")
                        {
                            // Remove if moved > 10 units otherwise reset
                            if (Math.abs(queueListItem.x - startX) > units.gu(10))
                            {
                                /*
                                 * Remove the listitem
                                 *
                                 * Remove the listitem to relevant side (queueListItemRemoveAnimation)
                                 * Reduce height of listitem and remove the item
                                 *   (swipeDeleteAnimation [called on queueListItemRemoveAnimation complete])
                                 */
                                swipeBackground.runSwipeDeletePrepareAnimation();  // fade out the clear text
                                queueListItemRemoveAnimation.start();  // remove item from listview
                            }
                            else
                            {
                                /*
                                 * Reset the listitem
                                 *
                                 * Remove the swipeDelete to relevant side (swipeResetAnimation)
                                 * Reset the listitem to the centre (queueListItemResetAnimation)
                                 */
                                queueListItemResetAnimation.start();  // reset item position
                            }
                        }

                        // ensure states are normal
                        swipeBackground.state = "normal";
                        queuelist.state = "normal";
                    }

                    // Animation to reset the x, y of the queueitem
                    ParallelAnimation {
                        id: queueListItemResetAnimation
                        running: false
                        NumberAnimation {  // reset X
                            target: queueListItem
                            property: "x"
                            to: queueArea.startX
                            duration: queuelist.transitionDuration
                        }
                        NumberAnimation {  // reset Y
                            target: queueListItem
                            property: "y"
                            to: queueArea.startY
                            duration: queuelist.transitionDuration
                        }
                    }

                    /*
                     * Animation to remove an item from the list
                     * - Removes listitem to relevant side
                     * - Calls swipeDeleteAnimation to delete the listitem
                     */
                    NumberAnimation {
                        id: queueListItemRemoveAnimation
                        target: queueListItem
                        property: "x"
                        to: swipeBackground.state == "swipingRight" ? queueListItem.width : 0 - queueListItem.width
                        duration: queuelist.transitionDuration

                        onRunningChanged: {
                            // Remove from queue once animation has finished
                            if (running == false)
                            {
                                swipeBackground.runSwipeDeleteAnimation();
                            }
                        }
                    }
                }

                onFocusChanged: {
                    if (focus == false) {
                        selected = false
                    } else {
                        selected = false
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
                        duration: queuelist.transitionDuration;
                        to: units.gu(2)
                    }

                    NumberAnimation {
                        id: trackContainerResetAnimation
                        target: trackContainer;
                        property: "anchors.leftMargin";
                        duration: queuelist.transitionDuration;
                        to: units.gu(0.5)
                    }

                    UbuntuShape {
                        id: trackImage
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(1.5)
                        anchors.top: parent.top
                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height
                        width: height
                        image: Image {
                            source: cover !== "" ? cover : "images/cover_default.png"
                        }
                        onHeightChanged: {
                            if (height > units.gu(7)) {
                                anchors.left = undefined
                                anchors.horizontalCenter = parent.horizontalCenter
                            } else {
                                anchors.left = parent.left
                                anchors.horizontalCenter = undefined
                            }
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
                        id: nowPlayingTitle
                        anchors.top: parent.top
                        anchors.topMargin: units.gu(0.5)
                        color: styleMusic.common.white
                        elide: Text.ElideRight
                        height: units.gu(1)
                        text: title
                        width: expandItem.x - x - units.gu(1.5)
                        x: trackImage.x + trackImage.width + units.gu(1)
                    }
                    Label {
                        id: nowPlayingAlbumArtist
                        anchors.top: nowPlayingTitle.bottom
                        anchors.topMargin: units.gu(1)
                        color: styleMusic.nowPlaying.labelSecondaryColor
                        elide: Text.ElideRight
                        text: artist + " - " + album
                        width: expandItem.x - x - units.gu(1.5)
                        x: trackImage.x + trackImage.width + units.gu(1)
                    }
                    Icon {
                        id: expandItem
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(2)
                        anchors.top: parent.top
                        anchors.topMargin: units.gu(2)
                        name: "add"
                        height: styleMusic.common.expandedItem
                        width: styleMusic.common.expandedItem
                    }

                    MouseArea {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.top: parent.top
                        width: styleMusic.common.expandedItem * 3
                        onClicked: {
                           chosenArtist = artist
                           chosenTitle = title
                           chosenTrack = file
                           chosenAlbum = album
                           chosenCover = cover
                           chosenGenre = genre
                           chosenIndex = index
                           customdebug("Add track to playlist")
                           PopupUtils.open(Qt.resolvedUrl("MusicaddtoPlaylist.qml"), mainView,
                           {
                               title: i18n.tr("Select playlist")
                           } )
                       }
                   }
                }
                states: State {
                    name: "current"
                    PropertyChanges {
                        target: queueListItem
                        height: queuelist.currentHeight
                    }
                    PropertyChanges {
                        target: nowPlayingTitle
                        width: expandItem.x - x - units.gu(2.5)
                        x: trackImage.x + units.gu(1)
                    }
                    PropertyChanges {
                        target: nowPlayingAlbumArtist
                        width: expandItem.x - x - units.gu(2.5)
                        x: trackImage.x + units.gu(1)
                    }
                    PropertyChanges {
                        target: expandItem

                    }

                    PropertyChanges {
                        target: trackBg
                        opacity: 0.75
                    }
                }
                transitions: Transition {
                    from: ",current"
                    to: "current,"
                    NumberAnimation {
                        duration: queuelist.transitionDuration
                        properties: "height,opacity,width,x"
                    }

                    onRunningChanged: {
                        if (running === false && ensureVisibleIndex != -1)
                        {
                            queuelist.positionViewAtIndex(ensureVisibleIndex, ListView.Visible);
                            ensureVisibleIndex = -1;
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: nowPlayingBackButton
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        color: styleMusic.nowPlaying.foregroundColor
        height: units.gu(3)

        Image {
            id: expandItem
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            source: "images/dropdown-menu.svg"
            height: units.gu(2)
            width: height
        }

        MouseArea {
            anchors.fill: parent

            onClicked: {
                musicToolbar.goBack();
            }
        }
    }
}
