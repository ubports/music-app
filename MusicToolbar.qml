/*
 * Copyright (C) 2013, 2014
 *      Andrew Hayzen <ahayzen@gmail.com>
 *      Daniel Holm <d.holmen@gmail.com>
 *      Victor Thompson <victor.thompson@gmail.com>
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
import QtQuick.LocalStorage 2.0
import QtMultimedia 5.0
import Ubuntu.Components 0.1
import Ubuntu.Components.Popups 0.1
import "settings.js" as Settings

Item {
    anchors {
        bottom: parent.bottom
        left: parent.left
        right: parent.right
    }

    // Properties storing the current page info
    property var currentParentPage: null
    property var currentPageStack: null
    property var currentPage: null
    property var currentSheet: []
    property var currentTab: null

    // Properties and signals for the toolbar
    property var cachedStates: []
    property bool shown: false
    property int transitionDuration: 100

    property alias minimizedHeight: musicToolbarPanel.minimizedHeight
    property alias expandedHeight: musicToolbarPanel.expandedHeight
    property alias fullHeight: musicToolbarPanel.fullHeight
    property alias mouseAreaOffset: musicToolbarPanel.hintSize

    property alias animating: musicToolbarPanel.animating
    property alias opened: musicToolbarPanel.opened

    /* Helper functions */

    // Disable the toolbar for this page/view (eg a dialog)
    function disableToolbar()
    {
        cachedStates.push(state);
        musicToolbarPanel.state = "hidden";
    }

    // Enable the toolbar (run when closing a page that disabled it)
    function enableToolbar()
    {
        if (cachedStates.length > 0)
        {
            musicToolbarPanel.state = cachedStates.pop();
        }
    }

    // Back button has been pressed, jump up pageStack or back to parent page
    function goBack()
    {
        if (currentSheet.length > 0) {
            PopupUtils.close(currentSheet[currentSheet.length - 1])
            return;  // don't change toolbar state when going back from sheet
        }
        else if (currentPageStack !== null) {
            currentPageStack.pop(currentPage)
        }
        else if (currentParentPage !== null) {
            currentParentPage.visible = false  // force switch
            currentPage.visible = false
            currentParentPage.visible = true
        }

        hideToolbar();
    }

    // Hide the toolbar
    function hideToolbar()
    {
        if (!wideAspect) {
            musicToolbarPanel.close();
        }

        toolbarAutoHideTimer.stop();  // cancel any autohide
    }

    // Remove sheet as it has been closed
    function removeSheet(sheet)
    {
        var index = currentSheet.lastIndexOf(sheet);

        if (index > -1) {
            currentSheet.splice(index, 1);
        }
    }

    // Set the current page, and any parent/stacks
    function setPage(childPage, parentPage, pageStack)
    {
        currentPage = childPage;
        currentParentPage = parentPage === undefined ? null : parentPage;
        currentPageStack = pageStack === undefined ? null : pageStack;
    }

    // Set the current sheet (overrides page)
    function setSheet(sheet) {
        currentSheet.push(sheet)
    }

    // Show the toolbar
    function showToolbar()
    {
        startAutohideTimer();  // always attempt to autohide toolbar

        if (!musicToolbarPanel.opened) {
            musicToolbarPanel.open();
        }
    }

    // Start the autohidetimer
    function startAutohideTimer()
    {
        toolbarAutoHideTimer.restart();
    }

    Connections {
        target: mainView
        onWideAspectChanged: {
            // Force toolbar to show if in wideAspect
            if (wideAspect && !opened) {
                showToolbar();
            }
        }
    }

    Panel {
        id: musicToolbarPanel
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: currentMode === "full" ? fullHeight : expandedHeight
        locked: wideAspect

        __closeOnContentsClicks: false  // TODO: fix bug 1295720

        // The current mode of the controls
        property string currentMode: wideAspect || (currentPage === nowPlaying)
                                     ? "full" : "expanded"

        // Properties for the different heights
        property int minimizedHeight: units.gu(0.5)
        property int expandedHeight: units.gu(8)
        property int fullHeight: units.gu(11)

        onCurrentModeChanged: {
            musicToolbarFullProgressMouseArea.enabled = currentMode === "full"
        }

        onOpenedChanged: {
            onToolbarShownChanged(opened, currentPage, currentTab);

            if (opened) {
                startAutohideTimer();
            }
        }

        /* Full toolbar */
        Rectangle {
            id: musicToolbarFullContainer
            anchors {
                fill: parent
            }
            color: styleMusic.toolbar.fullBackgroundColor
            visible: musicToolbarPanel.currentMode === "full"

            /* Buttons component */
            Rectangle {
                id: musicToolbarFullButtonsContainer
                anchors.left: parent.left
                anchors.top: musicToolbarFullProgressContainer.bottom
                color: "transparent"
                height: parent.height - musicToolbarFullProgressContainer.height
                width: parent.width

                /* Column for labels in wideAspect */
                Column {
                    id: nowPlayingWideAspectLabels
                    anchors {
                        left: parent.left
                        leftMargin: units.gu(1)
                        right: nowPlayingRepeatButton.left
                        rightMargin: units.gu(1)
                        verticalCenter: parent.verticalCenter
                    }
                    visible: wideAspect

                    /* Clicking in the area shows the queue */
                    function trigger() {
                        if (trackQueue.model.count !== 0 && currentPage !== nowPlaying) {
                            tabs.pushNowPlaying();
                        }
                        else if (currentPage === nowPlaying) {
                            musicToolbar.goBack();
                        }
                    }

                    /* Title of track */
                    Label {
                        id: nowPlayingWideAspectTitle
                        anchors {
                            left: parent.left
                            leftMargin: units.gu(1)
                            right: parent.right
                            rightMargin: units.gu(1)
                        }
                        color: styleMusic.playerControls.labelColor
                        elide: Text.ElideRight
                        fontSize: "medium"
                        objectName: "playercontroltitle"
                        text: trackQueue.model.count === 0 ? "" : player.currentMetaTitle === "" ? player.currentMetaFile : player.currentMetaTitle
                    }

                    /* Artist of track */
                    Label {
                        id: nowPlayingWideAspectArtist
                        anchors {
                            left: parent.left
                            leftMargin: units.gu(1)
                            right: parent.right
                            rightMargin: units.gu(1)
                        }
                        color: styleMusic.playerControls.labelColor
                        elide: Text.ElideRight
                        fontSize: "small"
                        text: trackQueue.model.count === 0 ? "" : player.currentMetaArtist
                    }

                    /* Album of track */
                    Label {
                        id: nowPlayingWideAspectAlbum
                        anchors {
                            left: parent.left
                            leftMargin: units.gu(1)
                            right: parent.right
                            rightMargin: units.gu(1)
                        }
                        color: styleMusic.playerControls.labelColor
                        elide: Text.ElideRight
                        fontSize: "small"
                        text: trackQueue.model.count === 0 ? "" : player.currentMetaAlbum
                    }
                }

                /* Repeat button */
                Item {
                    id: nowPlayingRepeatButton
                    objectName: "repeatShape"
                    anchors.right: nowPlayingPreviousButton.left
                    anchors.rightMargin: units.gu(1)
                    anchors.verticalCenter: parent.verticalCenter
                    height: units.gu(6)
                    opacity: player.repeat && !emptyPage.noMusic ? 1 : .4
                    width: height

                    function trigger() {
                        if (emptyPage.noMusic) {
                            return;
                        }

                        // Invert repeat settings
                        player.repeat = !player.repeat
                    }

                    Image {
                        id: repeatIcon
                        height: units.gu(3)
                        width: height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        source: Qt.resolvedUrl("images/media-playlist-repeat.svg")
                        verticalAlignment: Text.AlignVCenter
                        opacity: player.repeat && !emptyPage.noMusic ? 1 : .4
                    }
                }

                /* Previous button */
                Item {
                    id: nowPlayingPreviousButton
                    anchors.right: nowPlayingPlayButton.left
                    anchors.rightMargin: units.gu(1)
                    anchors.verticalCenter: parent.verticalCenter
                    height: units.gu(6)
                    objectName: "previousshape"
                    opacity: trackQueue.model.count === 0  ? .4 : 1
                    width: height

                    function trigger() {
                        if (trackQueue.model.count === 0) {
                            return;
                        }

                        player.previousSong()
                    }

                    Image {
                        id: nowPlayingPreviousIndicator
                        height: units.gu(3)
                        width: height
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        source: Qt.resolvedUrl("images/media-skip-backward.svg")
                        opacity: 1
                    }
                }

                /* Play/Pause button */
                Rectangle {
                    id: nowPlayingPlayButton
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    antialiasing: true
                    color: styleMusic.toolbar.fullOuterPlayCircleColor
                    height: units.gu(12)
                    radius: height / 2
                    width: height

                    // draws the outter shadow/highlight
                    Rectangle {
                        id: sourceOutterFull
                        anchors { fill: parent; margins: -units.gu(0.1) }
                        radius: (width / 2)
                        antialiasing: true
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "black" }
                            GradientStop { position: 0.5; color: "transparent" }
                            GradientStop { position: 1.0; color: UbuntuColors.warmGrey }
                        }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            antialiasing: true
                            color: styleMusic.toolbar.fullOuterPlayCircleColor
                            height: nowPlayingPlayButton.height - units.gu(.1)
                            radius: height / 2
                            width: height

                            Rectangle {
                                id: nowPlayingPlayButtonInner
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                                antialiasing: true
                                color: styleMusic.toolbar.fullInnerPlayCircleColor
                                height: units.gu(7)
                                radius: height / 2
                                width: height

                                // draws the inner shadow/highlight
                                Rectangle {
                                    id: sourceInnerFull
                                    anchors { fill: parent; margins: -units.gu(0.1) }
                                    radius: (width / 2)
                                    antialiasing: true
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: UbuntuColors.warmGrey }
                                        GradientStop { position: 0.5; color: "transparent" }
                                        GradientStop { position: 1.0; color: "black" }
                                    }

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.verticalCenter: parent.verticalCenter
                                        antialiasing: true
                                        color: styleMusic.toolbar.fullInnerPlayCircleColor
                                        height: nowPlayingPlayButtonInner.height - units.gu(.1)
                                        objectName: "nowPlayingPlayShape"
                                        radius: height / 2
                                        width: height

                                        function trigger() {
                                            if (emptyPage.noMusic) {
                                                return;
                                            }

                                            if (trackQueue.model.count === 0) {
                                                playRandomSong();
                                            }
                                            else {
                                                player.toggle();
                                            }
                                        }

                                        Image {
                                            id: nowPlayingPlayIndicator
                                            height: units.gu(6)
                                            width: height
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.verticalCenter: parent.verticalCenter
                                            opacity: emptyPage.noMusic ? .4 : 1
                                            source: player.playbackState === MediaPlayer.PlayingState ?
                                                        Qt.resolvedUrl("images/media-playback-pause.svg") : Qt.resolvedUrl("images/media-playback-start.svg")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                /* Next button */
                Item {
                    id: nowPlayingNextButton
                    anchors.left: nowPlayingPlayButton.right
                    anchors.leftMargin: units.gu(1)
                    anchors.verticalCenter: parent.verticalCenter
                    height: units.gu(6)
                    objectName: "forwardshape"
                    opacity: trackQueue.model.count === 0 ? .4 : 1
                    width: height

                    function trigger() {
                        if (trackQueue.model.count === 0 || emptyPage.noMusic) {
                            return;
                        }

                        player.nextSong()
                    }

                    Image {
                        id: nowPlayingNextIndicator
                        height: units.gu(3)
                        width: height
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        source: Qt.resolvedUrl("images/media-skip-forward.svg")
                        opacity: 1
                    }
                }

                /* Shuffle button */
                Item {
                    id: nowPlayingShuffleButton
                    objectName: "shuffleShape"
                    anchors.left: nowPlayingNextButton.right
                    anchors.leftMargin: units.gu(1)
                    anchors.verticalCenter: parent.verticalCenter
                    height: units.gu(6)
                    opacity: player.shuffle && !emptyPage.noMusic ? 1 : .4
                    width: height

                    function trigger() {
                        if (emptyPage.noMusic) {
                            return;
                        }

                        // Invert shuffle settings
                        player.shuffle = !player.shuffle
                    }

                    Image {
                        id: shuffleIcon
                        height: units.gu(3)
                        width: height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        source: Qt.resolvedUrl("images/media-playlist-shuffle.svg")
                        opacity: player.shuffle && !emptyPage.noMusic ? 1 : .4
                    }
                }

                /* Search button in wideAspect */
                Item {
                    id: nowPlayingSearchButton
                    objectName: "searchShape"
                    anchors {
                        right: parent.right
                        rightMargin: units.gu(1)
                        verticalCenter: parent.verticalCenter
                    }
                    height: units.gu(6)
                    opacity: !emptyPage.noMusic ? 1 : .4
                    width: height
                    visible: wideAspect

                    function trigger() {
                        if (emptyPage.noMusic) {
                            return;
                        }

                        if (!searchSheet.sheetVisible) {
                            PopupUtils.open(searchSheet.sheet,
                                            mainView, { title: i18n.tr("Search")} )
                        }
                    }

                    Image {
                        id: searchIcon
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            verticalCenter: parent.verticalCenter
                        }
                        height: units.gu(3)
                        opacity: !emptyPage.noMusic ? 1 : .4
                        source: Qt.resolvedUrl("images/search.svg")
                        width: height
                    }
                }
            }

            /* Progress bar component */
            Rectangle {
                id: musicToolbarFullProgressContainer
                anchors.left: parent.left
                anchors.top: parent.top
                color: styleMusic.toolbar.fullBackgroundColor
                height: units.gu(3)
                width: parent.width

                /* Position label */
                Label {
                    id: musicToolbarFullPositionLabel
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(2)
                    anchors.top: parent.top
                    color: styleMusic.nowPlaying.labelColor
                    fontSize: "x-small"
                    height: parent.height
                    horizontalAlignment: Text.AlignHCenter
                    text: durationToString(player.position)
                    verticalAlignment: Text.AlignVCenter
                    width: units.gu(3)
                }

                /* Progress bar */
                Rectangle {
                    id: musicToolbarFullProgressBarContainer
                    objectName: "progressBarShape"
                    anchors.left: musicToolbarFullPositionLabel.right
                    anchors.leftMargin: units.gu(2)
                    anchors.right: musicToolbarFullDurationLabel.left
                    anchors.rightMargin: units.gu(2)
                    anchors.verticalCenter: parent.verticalCenter
                    color: "transparent"
                    height: units.gu(1);
                    state: trackQueue.model.count === 0 ? "disabled" : "enabled"

                    states: [
                        State {
                            name: "disabled"
                            PropertyChanges {
                                target: musicToolbarFullProgressMouseArea
                                enabled: false
                            }
                            PropertyChanges {
                                target: musicToolbarFullProgressTrough
                                visible: false
                            }
                            PropertyChanges {
                                target: musicToolbarFullProgressHandle
                                visible: false
                            }
                        },
                        State {
                            name: "enabled"
                            PropertyChanges {
                                target: musicToolbarFullProgressMouseArea
                                enabled: true
                            }
                            PropertyChanges {
                                target: musicToolbarFullProgressTrough
                                visible: true
                            }
                            PropertyChanges {
                                target: musicToolbarFullProgressHandle
                                visible: true
                            }
                        }
                    ]

                    property bool seeking: false

                    onSeekingChanged: {
                        if (seeking === false) {
                            musicToolbarFullPositionLabel.text = durationToString(player.position)
                        }
                    }

                    Connections {
                        target: player
                        onDurationChanged: {
                            console.debug("Duration changed: " + player.duration)
                            musicToolbarFullDurationLabel.text = durationToString(player.duration)
                        }
                        onPositionChanged: {
                            if (musicToolbarFullProgressBarContainer.seeking === false)
                            {
                                musicToolbarFullPositionLabel.text = durationToString(player.position);
                                musicToolbarFullProgressHandle.x = (player.position / player.duration) * musicToolbarFullProgressBarContainer.width
                                        - musicToolbarFullProgressHandle.width / 2;
                            }
                        }
                        onStopped: {
                            musicToolbarFullProgressHandle.x = -musicToolbarFullProgressHandle.width / 2;

                            musicToolbarFullPositionLabel.text = durationToString(0);
                            musicToolbarFullDurationLabel.text = durationToString(0);
                        }
                    }

                    // Black background behind the progress bar
                    Rectangle {
                        id: musicToolbarFullProgressBackground
                        anchors.verticalCenter: parent.verticalCenter;
                        color: styleMusic.toolbar.fullProgressBackgroundColor;
                        height: parent.height;
                        radius: units.gu(0.5)
                        width: parent.width;
                    }

                    // The orange fill of the progress bar
                    Rectangle {
                        id: musicToolbarFullProgressTrough
                        anchors.verticalCenter: parent.verticalCenter;
                        antialiasing: true
                        color: styleMusic.toolbar.fullProgressTroughColor;
                        height: parent.height;
                        radius: units.gu(0.5)
                        width: musicToolbarFullProgressHandle.x + (height / 2);  // +radius
                    }

                    // The current position (handle) of the progress bar
                    Rectangle {
                        id: musicToolbarFullProgressHandle
                        anchors.verticalCenter: musicToolbarFullProgressBackground.verticalCenter
                        antialiasing: true
                        color: styleMusic.nowPlaying.progressHandleColor
                        height: units.gu(1.5)
                        radius: height / 2
                        width: height

                        // On X change update the position string
                        onXChanged: {
                            if (musicToolbarFullProgressBarContainer.seeking) {
                                var fraction = (x + (width / 2)) / parent.width;
                                musicToolbarFullPositionLabel.text = durationToString(fraction * player.duration)
                            }
                        }
                    }
                }

                /* Duration label */
                Label {
                    id: musicToolbarFullDurationLabel
                    anchors.right: parent.right
                    anchors.rightMargin: units.gu(2)
                    anchors.top: parent.top
                    color: styleMusic.nowPlaying.labelColor
                    fontSize: "x-small"
                    height: parent.height
                    horizontalAlignment: Text.AlignHCenter
                    text: durationToString(player.duration)
                    verticalAlignment: Text.AlignVCenter
                    width: units.gu(3)
                }

                /* Border at the bottom */
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    color: styleMusic.common.white
                    height: units.gu(0.1)
                    opacity: 0.1
                }
            }
        }

        /* Expanded toolbar */
        Rectangle {
            id: musicToolbarExpandedContainer
            anchors {
                fill: parent
            }
            color: "transparent"
            visible: musicToolbarPanel.currentMode === "expanded"

            Rectangle {
                id: musicToolbarPlayerControls
                anchors.fill: parent
                color: styleMusic.playerControls.backgroundColor
                state: trackQueue.model.count === 0 ? "disabled" : "enabled"
                states: [
                    State {
                        name: "disabled"
                        PropertyChanges {
                            target: disabledPlayerControlsGroup
                            visible: true
                        }
                        PropertyChanges {
                            target: enabledPlayerControlsGroup
                            visible: false
                        }
                    },
                    State {
                        name: "enabled"
                        PropertyChanges {
                            target: disabledPlayerControlsGroup
                            visible: false
                        }
                        PropertyChanges {
                            target: enabledPlayerControlsGroup
                            visible: true
                        }
                    }
                ]

                Rectangle {
                    id: disabledPlayerControlsGroup
                    anchors.fill: parent
                    color: "transparent"
                    visible: trackQueue.model.count === 0

                    Label {
                        id: noSongsInQueueLabel
                        anchors.left: parent.left
                        anchors.margins: units.gu(1)
                        anchors.top: parent.top
                        color: styleMusic.playerControls.labelColor
                        text: i18n.tr("No songs queued")
                        fontSize: "large"
                    }

                    Label {
                        id: tabToStartPlayingLabel
                        color: styleMusic.playerControls.labelColor
                        anchors.left: parent.left
                        anchors.margins: units.gu(1)
                        anchors.top: noSongsInQueueLabel.bottom
                        text: i18n.tr("Tap play or any item to start")
                    }

                    Rectangle {
                        id: disabledPlayerControlsPlayButton
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1)
                        anchors.verticalCenter: parent.verticalCenter
                        antialiasing: true
                        color: "#444"
                        height: units.gu(7)
                        radius: height / 2
                        width: height

                        function trigger() {
                            if (emptyPage.noMusic) {
                                return;
                            }

                            if (trackQueue.model.count === 0) {
                                playRandomSong();
                            }
                            else {
                                player.toggle();
                            }
                        }

                        // draws the outer shadow/highlight
                        Rectangle {
                            id: disabledSourceOutter
                            anchors { fill: parent; margins: -units.gu(0.1) }
                            radius: (width / 2)
                            antialiasing: true
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "black" }
                                GradientStop { position: 0.5; color: "transparent" }
                                GradientStop { position: 1.0; color: UbuntuColors.warmGrey }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                                antialiasing: true
                                color: "#444"
                                height: playerControlsPlayButton.height - units.gu(.1)
                                radius: height / 2
                                width: height

                                Rectangle {
                                    id: disabledPlayerControlsPlayInnerCircle
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    antialiasing: true
                                    height: units.gu(4.5)
                                    radius: height / 2
                                    width: height
                                    color: styleMusic.toolbar.fullInnerPlayCircleColor

                                    // draws the inner shadow/highlight
                                    Rectangle {
                                        id: disabledSourceInner
                                        anchors { fill: parent; margins: -units.gu(0.1) }
                                        radius: (width / 2)
                                        antialiasing: true
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: UbuntuColors.warmGrey }
                                            GradientStop { position: 0.5; color: "transparent" }
                                            GradientStop { position: 1.0; color: "black" }
                                        }

                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            antialiasing: true
                                            height: playerControlsPlayInnerCircle.height - units.gu(.1)
                                            radius: height / 2
                                            width: height
                                            color: styleMusic.toolbar.fullInnerPlayCircleColor

                                            Image {
                                                id: disabledPlayIndicator
                                                height: units.gu(4)
                                                width: height
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.verticalCenter: parent.verticalCenter
                                                opacity: emptyPage.noMusic ? .4 : 1
                                                source: player.playbackState === MediaPlayer.PlayingState ?
                                                            Qt.resolvedUrl("images/media-playback-pause.svg") : Qt.resolvedUrl("images/media-playback-start.svg")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: enabledPlayerControlsGroup
                    anchors.fill: parent
                    color: "transparent"
                    visible: trackQueue.model.count !== 0

                    /* Settings button */
                    // TODO: Enable settings when it is practical
                    /* Rectangle {
                        id: playerControlsSettings
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: units.gu(6)
                        height: width
                        color: "transparent"

                        Image {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            height: units.gu(3)
                            source: Qt.resolvedUrl("images/settings.png")
                            width: height
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                console.debug('Debug: Show settings')
                                PopupUtils.open(Qt.resolvedUrl("MusicSettings.qml"), mainView,
                                                {
                                                    title: i18n.tr("Settings")
                                                } )
                            }
                        }
                    } */

                    /* Play/Pause button TODO: image and colours needs updating */
                    Rectangle {
                        id: playerControlsPlayButton
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1)
                        anchors.verticalCenter: parent.verticalCenter
                        antialiasing: true
                        color: "#444"
                        height: units.gu(7)
                        objectName: "playshape"
                        radius: height / 2
                        width: height

                        function trigger() {
                            if (emptyPage.noMusic) {
                                return;
                            }

                            if (trackQueue.model.count === 0) {
                                playRandomSong();
                            }
                            else {
                                player.toggle();
                            }
                        }

                        // draws the outer shadow/highlight
                        Rectangle {
                            id: sourceOutter
                            anchors { fill: parent; margins: -units.gu(0.1) }
                            radius: (width / 2)
                            antialiasing: true
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "black" }
                                GradientStop { position: 0.5; color: "transparent" }
                                GradientStop { position: 1.0; color: UbuntuColors.warmGrey }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                                antialiasing: true
                                color: "#444"
                                height: playerControlsPlayButton.height - units.gu(.1)
                                radius: height / 2
                                width: height

                                Rectangle {
                                    id: playerControlsPlayInnerCircle
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    antialiasing: true
                                    height: units.gu(4.5)
                                    radius: height / 2
                                    width: height
                                    color: styleMusic.toolbar.fullInnerPlayCircleColor

                                    // draws the inner shadow/highlight
                                    Rectangle {
                                        id: sourceInner
                                        anchors { fill: parent; margins: -units.gu(0.1) }
                                        radius: (width / 2)
                                        antialiasing: true
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: UbuntuColors.warmGrey }
                                            GradientStop { position: 0.5; color: "transparent" }
                                            GradientStop { position: 1.0; color: "black" }
                                        }

                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            antialiasing: true
                                            height: playerControlsPlayInnerCircle.height - units.gu(.1)
                                            radius: height / 2
                                            width: height
                                            color: styleMusic.toolbar.fullInnerPlayCircleColor

                                            Image {
                                                id: playindicator
                                                height: units.gu(4)
                                                width: height
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.verticalCenter: parent.verticalCenter
                                                opacity: emptyPage.noMusic ? .4 : 1
                                                source: player.playbackState === MediaPlayer.PlayingState ?
                                                            Qt.resolvedUrl("images/media-playback-pause.svg") : Qt.resolvedUrl("images/media-playback-start.svg")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    /* Container holding the labels for the toolbar */
                    Rectangle {
                        id: playerControlLabelContainer
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: playerControlsPlayButton.left
                        anchors.top: parent.top
                        color: "transparent"

                        /* Title of track */
                        Label {
                            id: playerControlsTitle
                            anchors.left: parent.left
                            anchors.leftMargin: units.gu(1)
                            anchors.right: parent.right
                            anchors.rightMargin: units.gu(1)
                            anchors.top: parent.top
                            anchors.topMargin: units.gu(1)
                            color: styleMusic.playerControls.labelColor
                            elide: Text.ElideRight
                            fontSize: "medium"
                            objectName: "playercontroltitle"
                            text: player.currentMetaTitle === ""
                                  ? player.source : player.currentMetaTitle
                        }

                        /* Artist of track */
                        Label {
                            id: playerControlsArtist
                            anchors.left: parent.left
                            anchors.leftMargin: units.gu(1)
                            anchors.right: parent.right
                            anchors.rightMargin: units.gu(1)
                            anchors.top: playerControlsTitle.bottom
                            color: styleMusic.playerControls.labelColor
                            elide: Text.ElideRight
                            fontSize: "small"
                            text: player.currentMetaArtist
                        }

                        /* Album of track */
                        Label {
                            id: playerControlsAlbum
                            anchors.left: parent.left
                            anchors.leftMargin: units.gu(1)
                            anchors.right: parent.right
                            anchors.rightMargin: units.gu(1)
                            anchors.top: playerControlsArtist.bottom
                            color: styleMusic.playerControls.labelColor
                            elide: Text.ElideRight
                            fontSize: "small"
                            text: player.currentMetaAlbum
                        }
                    }

                    Rectangle {
                        anchors.fill: playerControlLabelContainer
                        color: "transparent"
                        function trigger() {
                            tabs.pushNowPlaying();
                        }
                    }
                }
            }
        }

        /* Object which provides the progress bar when toolbar is minimized */
        Rectangle {
            id: musicToolbarSmallProgressBackground
            anchors {
                bottom: parent.top
                left: parent.left
                right: parent.right
            }
            color: styleMusic.common.black
            height: musicToolbarPanel.minimizedHeight
            visible: (!musicToolbarPanel.animating &&
                        !musicToolbarPanel.opened)
                     || musicToolbarPanel.currentMode == "expanded"

            Rectangle {
                id: musicToolbarSmallProgressHint
                anchors.left: parent.left
                anchors.top: parent.top
                color: styleMusic.nowPlaying.progressForegroundColor
                height: parent.height
                width: 0

                Connections {
                    target: player
                    onPositionChanged: {
                        musicToolbarSmallProgressHint.width = (player.position / player.duration) * musicToolbarSmallProgressBackground.width
                    }
                    onStopped: {
                        musicToolbarSmallProgressHint.width = 0;
                    }
                }
            }
        }

        /* Mouse events for the progress bar
               is after musicToolbarMouseArea so that it captures mouse events for dragging */
        MouseArea {
            id: musicToolbarFullProgressMouseArea
            height: units.gu(2)
            width: musicToolbarFullProgressBarContainer.width
            x: musicToolbarFullProgressBarContainer.x
            y: musicToolbarFullProgressBarContainer.y

            drag.axis: Drag.XAxis
            drag.minimumX: -(musicToolbarFullProgressHandle.width / 2)
            drag.maximumX: musicToolbarFullProgressBarContainer.width - (musicToolbarFullProgressHandle.width / 2)
            drag.target: musicToolbarFullProgressHandle

            onPressed: {
                musicToolbarFullProgressBarContainer.seeking = true;

                // Jump the handle to the current mouse position
                musicToolbarFullProgressHandle.x = mouse.x - (musicToolbarFullProgressHandle.width / 2);
            }

            onReleased: {
                var fraction = mouse.x / musicToolbarFullProgressBarContainer.width;

                // Limit the bounds of the fraction
                fraction = fraction < 0 ? 0 : fraction
                fraction = fraction > 1 ? 1 : fraction

                player.seek((fraction) * player.duration);
                musicToolbarFullProgressBarContainer.seeking = false;
            }
        }

        // Timer for autohide
        Timer {
            id: toolbarAutoHideTimer
            interval: 5000
            repeat: false
            running: false
            onTriggered: {
                if (currentPage !== nowPlaying) {  // don't autohide on now playing
                    hideToolbar();
                }
            }
        }
    }
}

