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
            queuelist.scrollLock = true;
            header.hide();
            header.opacity = 0;
            header.enabled = false;
            musicToolbar.setPage(nowPlaying, musicToolbar.currentPage);
            queuelist.anchors.topMargin = -header.height + nowPlayingBackButton.height
            queuelist.scrollLock = false;
        }
        else
        {
            header.enabled = true;
            header.opacity = 1;
            header.show();
        }
    }

    property int ensureVisibleIndex: 0  // ensure first index is visible at startup

    Rectangle {
        anchors.fill: parent
        color: styleMusic.nowPlaying.backgroundColor
        opacity: 0.95 // change later
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
            queuelist.scrollLock = true;

            // Then position the view at the current index
            queuelist.positionViewAtIndex(queuelist.currentIndex, ListView.Beginning);
            if (queuelist.contentY > 0)
            {
                queuelist.contentY -= header.height;
            }

            queuelist.scrollLock = false;
        }
    }

    function updateCurrentIndex(file)
    {
        var index = trackQueue.indexOf(file);

        // Collapse currently expanded track and the new current
        collapseExpand(queuelist.currentIndex);
        collapseExpand(index);

        queuelist.currentIndex = index;

        customdebug("MusicQueue update currentIndex: " + file);
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

        property bool scrollLock: false

        onContentYChanged: {
            if (!scrollLock)
            {
                musicToolbar.hideToolbar();
            }
        }

        property int normalHeight: units.gu(10)
        property int currentHeight: units.gu(50)
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

                // cached height used to restore the height after expansion
                property int cachedHeight: -1

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
                            collapseExpand(-1);  // collapse all
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
                        height: (queueListItem.state === "current" ? queuelist.currentHeight - units.gu(8) : queuelist.normalHeight) - units.gu(1)
                        width: height
                        image: Image {
                            source: cover !== "" ? cover : "images/cover_default.png"
                        }
                        onHeightChanged: {
                            if (height > queuelist.normalHeight) {
                                anchors.left = undefined
                                anchors.horizontalCenter = parent.horizontalCenter
                            } else {
                                anchors.left = parent.left
                                anchors.horizontalCenter = undefined
                            }
                        }
                        Behavior on height {
                            NumberAnimation {
                                target: trackImage;
                                property: "height";
                                duration: queuelist.transitionDuration;
                            }
                        }
                    }
                    Label {
                        id: nowPlayingArtist
                        color: styleMusic.nowPlaying.labelSecondaryColor
                        elide: Text.ElideRight
                        height: units.gu(1)
                        text: artist
                        fontSize: 'small'
                        width: expandItem.x - x - units.gu(1.5)
                        x: trackImage.x + trackImage.width + units.gu(1)
                        y: trackImage.y + units.gu(1)
                    }
                    Label {
                        id: nowPlayingTitle
                        color: styleMusic.common.white
                        elide: Text.ElideRight
                        height: units.gu(1)
                        text: title
                        fontSize: 'medium'
                        width: expandItem.x - x - units.gu(1.5)
                        x: trackImage.x + trackImage.width + units.gu(1)
                        y: nowPlayingArtist.y + nowPlayingArtist.height + units.gu(1.25)
                    }
                    Label {
                        id: nowPlayingAlbum
                        color: styleMusic.nowPlaying.labelSecondaryColor
                        elide: Text.ElideRight
                        height: units.gu(1)
                        text: album
                        fontSize: 'x-small'
                        width: expandItem.x - x - units.gu(1.5)
                        x: trackImage.x + trackImage.width + units.gu(1)
                        y: nowPlayingTitle.y + nowPlayingTitle.height + units.gu(1.25)
                    }
                    Image {
                        id: expandItem
                        source: expandable.visible ? "images/dropdown-menu-up.svg" : "images/dropdown-menu.svg"
                        height: styleMusic.common.expandedItem
                        width: styleMusic.common.expandedItem
                        x: parent.x + parent.width - width - units.gu(2)
                        y: trackImage.y + (queuelist.normalHeight / 2) - (styleMusic.common.expandedItem / 2)
                    }

                    MouseArea {
                        id: expandItemMouseArea
                        height: queuelist.normalHeight
                        width: styleMusic.common.expandedItem * 3
                        x: parent.x + parent.width - width
                        y: trackImage.y

                        onClicked: {
                           if(expandable.visible) {
                               customdebug("clicked collapse");
                               expandable.visible = false;
                               queueListItem.height = queueListItem.cachedHeight;
                               Rotation: {
                                   source: expandItem;
                                   angle: 0;
                               }
                           }
                           else {
                               customdebug("clicked expand");
                               collapseExpand(-1);  // collapse all others first
                               expandable.visible = true;
                               queueListItem.cachedHeight = queueListItem.height;
                               queueListItem.height = queueListItem.state === "current" ? styleMusic.nowPlaying.expandedHeightCurrent : styleMusic.nowPlaying.expandedHeightNormal;
                               Rotation: {
                                   source: expandItem;
                                   angle: 180;
                               }
                           }
                       }
                   }
                }

                Rectangle {
                    id: expandable
                    visible: false
                    width: parent.fill
                    height: queueListItem.state === "current" ? styleMusic.nowPlaying.expandedHeightCurrent : styleMusic.nowPlaying.expandedHeightNormal
                    color: "black"
                    opacity: 0.7
                    MouseArea {
                       anchors.fill: parent
                       onClicked: {
                           customdebug("User pressed outside the playlist item and expanded items.")
                       }
                    }

                    Component.onCompleted: {
                        collapseExpand.connect(onCollapseExpand);
                    }

                    function onCollapseExpand(indexCol)
                    {
                        if ((indexCol === index || indexCol === -1) && expandable !== undefined && expandable.visible === true)
                        {
                            customdebug("auto collapse")
                            expandable.visible = false
                            queueListItem.height = queueListItem.cachedHeight
                            Rotation: {
                                source: expandItem;
                                angle: 0;
                            }
                        }
                    }

                    // add to playlist
                    Rectangle {
                        id: playlistRow
                        anchors.top: parent.top
                        anchors.topMargin: units.gu(1) + (queueListItem.state === "current" ? queuelist.currentHeight : queuelist.normalHeight)
                        anchors.left: parent.left
                        anchors.leftMargin: styleMusic.common.expandedLeftMargin
                        color: "transparent"
                        height: styleMusic.common.expandedItem
                        width: units.gu(15)
                        Icon {
                            id: playlistTrack
                            name: "add"
                            height: styleMusic.common.expandedItem
                            width: styleMusic.common.expandedItem
                        }
                        Label {
                            text: i18n.tr("Add to playlist")
                            wrapMode: Text.WordWrap
                            fontSize: "small"
                            anchors.left: playlistTrack.right
                            anchors.leftMargin: units.gu(0.5)
                        }
                        MouseArea {
                           anchors.fill: parent
                           onClicked: {
                               expandable.visible = false;
                               queueListItem.height = queueListItem.cachedHeight;
                               chosenArtist = artist;
                               chosenTitle = title;
                               chosenTrack = file;
                               chosenAlbum = album;
                               chosenCover = cover;
                               chosenGenre = genre;
                               chosenIndex = index;
                               console.debug("Debug: Add track to playlist");
                               PopupUtils.open(Qt.resolvedUrl("MusicaddtoPlaylist.qml"), mainView,
                               {
                                   title: i18n.tr("Select playlist")
                               } )
                           }
                        }
                    }
                    // Share
                    Rectangle {
                        id: shareRow
                        anchors.top: parent.top
                        anchors.topMargin: units.gu(2.5) + (queueListItem.state === "current" ? queuelist.currentHeight : queuelist.normalHeight)
                        anchors.left: playlistRow.left
                        anchors.leftMargin: units.gu(15)
                        color: "transparent"
                        height: styleMusic.common.expandedItem
                        width: units.gu(15)
                        visible: false
                        Icon {
                            id: shareTrack
                            name: "share"
                            height: styleMusic.common.expandedItem
                            width: styleMusic.common.expandedItem
                        }
                        Label {
                            text: i18n.tr("Share")
                            wrapMode: Text.WordWrap
                            fontSize: "small"
                            anchors.left: shareTrack.right
                            anchors.leftMargin: units.gu(0.5)
                        }
                        MouseArea {
                           anchors.fill: parent
                           onClicked: {
                               expandable.visible = false
                               track.height = styleMusic.common.itemHeight
                               customdebug("Share")
                           }
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
                        target: nowPlayingArtist
                        width: expandItem.x - x - units.gu(2.5)
                        x: trackImage.x + units.gu(2)
                        y: trackImage.y + trackImage.height + units.gu(0.5)
                    }
                    PropertyChanges {
                        target: nowPlayingTitle
                        width: expandItem.x - x - units.gu(2.5)
                        x: trackImage.x + units.gu(2)
                        y: nowPlayingArtist.y + nowPlayingArtist.height + units.gu(1.25)
                    }
                    PropertyChanges {
                        target: nowPlayingAlbum
                        width: expandItem.x - x - units.gu(2.5)
                        x: trackImage.x + units.gu(2)
                        y: nowPlayingTitle.y + nowPlayingTitle.height + units.gu(1.25)
                    }
                    PropertyChanges {
                        target: expandItem
                        x: trackImage.x + trackImage.width - expandItem.width - units.gu(2)
                        y: trackImage.y + trackImage.height + units.gu(4) - (expandItem.height / 2)
                    }
                    PropertyChanges {
                        target: expandItemMouseArea
                        x: trackImage.x + trackImage.width - expandItemMouseArea.width
                        y: trackImage.y + trackImage.height + units.gu(0.5)
                    }
                }
                transitions: Transition {
                    from: ",current"
                    to: "current,"
                    NumberAnimation {
                        duration: queuelist.transitionDuration
                        properties: "height,opacity,width,x,y"
                    }

                    onRunningChanged: {
                        if (running)
                        {
                            queuelist.scrollLock = true;
                        }

                        if (running === false && ensureVisibleIndex != -1)
                        {
                            queuelist.scrollLock = true;
                            queuelist.positionViewAtIndex(ensureVisibleIndex, ListView.Beginning);
                            queuelist.contentY -= header.height;
                            ensureVisibleIndex = -1;
                            queuelist.scrollLock = false;
                        }

                        if (!running)
                        {
                            queuelist.scrollLock = false;
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
        color: styleMusic.toolbar.fullBackgroundColor
        height: units.gu(3.1)

        state: musicToolbar.opened ? "shown" : "hidden"
        states: [
            State {
                name: "shown"
                PropertyChanges {
                    target: nowPlayingBackButton
                    y: 0
                }
            },
            State {
                name: "hidden"
                PropertyChanges {
                    target: nowPlayingBackButton
                    y: -height
                }
            }
        ]

        transitions: Transition {
             from: "hidden,shown"
             to: "shown,hidden"
             NumberAnimation {
                 duration: 100
                 properties: "y"
             }
         }

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

        /* Border at the bottom */
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            color: styleMusic.common.white
            height: units.gu(0.1)
            opacity: 0.2
        }
    }
}
