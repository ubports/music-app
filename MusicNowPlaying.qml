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
import Ubuntu.Components.ListItems 0.1 as ListItem
import "common"
import "meta-database.js" as Library
import "settings.js" as Settings

Page {
    id: nowPlaying
    objectName: "nowplayingpage"
    title: i18n.tr("Now Playing")
    tools: null
    visible: false

    onVisibleChanged: {
        if (visible === true)
        {
            musicToolbar.setPage(nowPlaying, null, tabs.pageStack);
        }
    }

    property int ensureVisibleIndex: 0  // ensure first index is visible at startup

    BlurredBackground {
    }

    Rectangle {
        anchors.fill: parent
        color: styleMusic.nowPlaying.backgroundColor
        opacity: 0.75 // change later
        MouseArea {  // Block events to lower layers
            anchors.fill: parent
        }
    }

    Component.onCompleted: {
        onToolbarShownChanged.connect(jumpToCurrent)
    }

    Connections {
        target: player
        onCurrentIndexChanged: {
            if (player.source === "") {
                return;
            }

            collapseExpand();  // Collapse expanded tracks
            queuelist.currentIndex = player.currentIndex;

            customdebug("MusicQueue update currentIndex: " + player.source);
        }
    }

    function jumpToCurrent(shown, currentPage, currentTab)
    {
        // If the toolbar is shown, the page is now playing and snaptrack is enabled
        if (shown && currentPage === nowPlaying && Settings.getSetting("snaptrack") === "1")
        {
            // Then position the view at the current index
            queuelist.positionViewAtIndex(queuelist.currentIndex, ListView.Beginning);
        }
    }

    function positionAt(index) {
        queuelist.positionViewAtIndex(index, ListView.Beginning);
        queuelist.contentY -= header.height;
    }

    ListView {
        id: queuelist
        objectName: "queuelist"
        anchors.fill: parent
        anchors.bottomMargin: musicToolbar.mouseAreaOffset + musicToolbar.minimizedHeight
        anchors.topMargin: nowPlayingBackButton.height
        spacing: units.gu(1)
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
        footer: Item {
            height: mainView.height - styleMusic.nowPlaying.expandedHeightCurrent + units.gu(8)
        }

        property int normalHeight: units.gu(12)
        property int currentHeight: units.gu(46)
        property int transitionDuration: 250  // transition length of animations

        onCountChanged: {
            customdebug("Queue: Now has: " + queuelist.count + " tracks")
        }

        onMovementStarted: {
            musicToolbar.hideToolbar();
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
                            queueListItemRemoveAnimation.start();
                        }
                    }
                }

                function onCollapseSwipeDelete(indexCol)
                {
                    if ((indexCol !== index || indexCol === -1) && swipeBackground !== undefined && swipeBackground.direction !== "")
                    {
                        customdebug("auto collapse swipeDelete")
                        queueListItemResetStartAnimation.start();
                    }
                }

                Component.onCompleted: {
                    collapseSwipeDelete.connect(onCollapseSwipeDelete);
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
                        collapseSwipeDelete(-1);  // collapse all expands
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
                            collapseSwipeDelete(-1);  // collapse all expands
                            collapseExpand();  // collapse all
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
                            var moved = Math.abs(queueListItem.x - startX);

                            // Make sure that item has been dragged far enough
                            if (moved > queueListItem.width / 2 || (swipeBackground.primed === true && moved > units.gu(5)))
                            {
                                if (swipeBackground.primed === false)
                                {
                                    collapseSwipeDelete(index);  // collapse other swipeDeletes

                                    // Move the listitem half way across to reveal the delete button
                                    queueListItemPrepareRemoveAnimation.start();
                                }
                                else
                                {
                                    // Check that actually swiping to cancel
                                    if (swipeBackground.direction !== "" &&
                                            swipeBackground.direction !== swipeBackground.state)
                                    {
                                        // Reset the listitem to the centre
                                        queueListItemResetStartAnimation.start();
                                    }
                                    else
                                    {
                                        // Reset the listitem to the centre
                                        queueListItemResetAnimation.start();
                                    }
                                }
                            }
                            else
                            {
                                // Reset the listitem to the centre
                                queueListItemResetAnimation.start();
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

                    // Animation to reset the x, y of the item
                    ParallelAnimation {
                        id: queueListItemResetStartAnimation
                        running: false
                        NumberAnimation {  // reset X
                            target: queueListItem
                            property: "x"
                            to: 0
                            duration: queuelist.transitionDuration
                        }
                        NumberAnimation {  // reset Y
                            target: queueListItem
                            property: "y"
                            to: queueArea.startY
                            duration: queuelist.transitionDuration
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
                        id: queueListItemPrepareRemoveAnimation
                        target: queueListItem
                        property: "x"
                        to: swipeBackground.state == "swipingRight" ? queueListItem.width / 2 : 0 - (queueListItem.width / 2)
                        duration: queuelist.transitionDuration
                        onRunningChanged: {
                            if (running === true)
                            {
                                swipeBackground.direction = swipeBackground.state;
                                swipeBackground.primed = true;
                            }
                        }
                    }

                    ParallelAnimation {
                        id: queueListItemRemoveAnimation
                        running: false
                        NumberAnimation {  // 'slide' up
                            target: queueListItem
                            property: "height"
                            to: 0
                            duration: queuelist.transitionDuration
                        }
                        NumberAnimation {  // 'slide' in direction of removal
                            target: queueListItem
                            property: "x"
                            to: swipeBackground.direction === "swipingLeft" ? 0 - queueListItem.width : queueListItem.width
                            duration: queuelist.transitionDuration
                        }
                        onRunningChanged: {
                            if (running === false)
                            {
                                // Remove the item
                                if (index == queuelist.currentIndex)
                                {
                                    if (queuelist.count > 1)
                                    {
                                        // Next song and only play if currently playing
                                        player.nextSong(player.isPlaying);
                                    }
                                    else
                                    {
                                        player.stop();
                                    }
                                }

                                if (index < player.currentIndex) {
                                    player.currentIndex -= 1;
                                }

                                // Remove item from queue and clear caches
                                trackQueue.model.remove(index);
                                queueChanged = true;
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
                    anchors {
                        fill: parent
                        margins: units.gu(0.5)
                        rightMargin: expandable.expanderButtonWidth
                    }
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
                        height: (queueListItem.state === "current" ? queuelist.currentHeight - units.gu(8) : queuelist.normalHeight) - units.gu(2)
                        width: height
                        image: Image {
                            source: cover !== "" ? cover : "images/music-app-cover@30.png"
                            onStatusChanged: {
                                if (status === Image.Error) {
                                    source = Qt.resolvedUrl("images/music-app-cover@30.png")
                                }
                            }
                        }
                        onHeightChanged: {
                            if (height > queuelist.normalHeight && wideAspect) {
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
                        objectName: "nowplayingartist"
                        color: styleMusic.nowPlaying.labelSecondaryColor
                        elide: Text.ElideRight
                        height: units.gu(1)
                        text: artist
                        fontSize: 'small'
                        width: parent.width - trackImage.width - units.gu(3.5)
                        x: trackImage.x + trackImage.width + units.gu(1)
                        y: trackImage.y + units.gu(1)
                    }
                    Label {
                        id: nowPlayingTitle
                        objectName: "nowplayingtitle"
                        color: styleMusic.common.white
                        elide: Text.ElideRight
                        height: units.gu(1)
                        text: title
                        fontSize: 'medium'
                        width: parent.width - trackImage.width - units.gu(3.5)
                        x: trackImage.x + trackImage.width + units.gu(1)
                        y: nowPlayingArtist.y + nowPlayingArtist.height + units.gu(1.25)
                    }
                    Label {
                        id: nowPlayingAlbum
                        objectName: "nowplayingalbum"
                        color: styleMusic.nowPlaying.labelSecondaryColor
                        elide: Text.ElideRight
                        height: units.gu(1)
                        text: album
                        fontSize: 'x-small'
                        width: parent.width - trackImage.width - units.gu(3.5)
                        x: trackImage.x + trackImage.width + units.gu(1)
                        y: nowPlayingTitle.y + nowPlayingTitle.height + units.gu(1.25)
                    }
                }

                Expander {
                    id: expandable
                    anchors {
                        fill: parent
                    }

                    addToPlaylist: true
                    listItem: queueListItem
                    model: trackQueue.model.get(index)
                }

                states: State {
                    name: "current"
                    PropertyChanges {
                        target: queueListItem
                        height: queuelist.currentHeight
                    }
                    PropertyChanges {
                        target: nowPlayingArtist
                        width: trackImage.width
                        x: trackImage.x
                        y: trackImage.y + trackImage.height + units.gu(0.5)
                    }
                    PropertyChanges {
                        target: nowPlayingTitle
                        width: trackImage.width
                        x: trackImage.x
                        y: nowPlayingArtist.y + nowPlayingArtist.height + units.gu(1.25)
                    }
                    PropertyChanges {
                        target: nowPlayingAlbum
                        width: trackImage.width
                        x: trackImage.x
                        y: nowPlayingTitle.y + nowPlayingTitle.height + units.gu(1.25)
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
                        if (running === false && ensureVisibleIndex != -1)
                        {
                            queuelist.positionViewAtIndex(ensureVisibleIndex, ListView.Beginning);
                            ensureVisibleIndex = -1;
                        }
                    }
                }
            }
        }
    }

    // TODO: Remove back button once lp:1256424 is fixed (button will be in header)
    Rectangle {
        id: nowPlayingBackButton
        anchors {
            left: parent.left
            right: parent.right
        }

        color: styleMusic.toolbar.fullBackgroundColor
        height: units.gu(3.1)
        y: header.y + header.height

        Image {
            id: nowPlayingBackButtonImage
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            source: "images/dropdown-menu.svg"
            height: units.gu(2)
            width: height
        }

        MouseArea {
            objectName: "nowPlayingBackButtonObject"
            anchors.fill: parent

            onClicked: {
                collapseSwipeDelete(-1);  // collapse all expands
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
