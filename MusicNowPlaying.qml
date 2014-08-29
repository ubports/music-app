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


import QtMultimedia 5.0
import QtQuick 2.2
import QtQuick.LocalStorage 2.0
import Ubuntu.Components 1.1
import Ubuntu.Thumbnailer 0.1
import "common"
import "common/ListItemActions"
import "settings.js" as Settings

MusicPage {
    id: nowPlaying
    objectName: "nowPlayingPage"
    title: i18n.tr("Now Playing")
    visible: false

    property int ensureVisibleIndex: 0  // ensure first index is visible at startup

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

            queuelist.currentIndex = player.currentIndex;

            customdebug("MusicQueue update currentIndex: " + player.source);

            // Always jump to current track
            nowPlaying.jumpToCurrent(musicToolbar.opened, nowPlaying, musicToolbar.currentTab)

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
        objectName: "nowPlayingQueueList"
        anchors.fill: parent
        anchors.bottomMargin: musicToolbar.mouseAreaOffset + musicToolbar.minimizedHeight
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
            height: mainView.height - (styleMusic.common.expandHeight + queuelist.currentHeight) + units.gu(8)
        }

        property int normalHeight: units.gu(12)
        property int currentHeight: units.gu(40)
        property int transitionDuration: 250  // transition length of animations

        onCountChanged: {
            customdebug("Queue: Now has: " + queuelist.count + " tracks")
        }

        onMovementStarted: {
            musicToolbar.hideToolbar();
        }

        Component {
            id: queueDelegate
            ListItemWithActions {
                id: queueListItem
                color: "transparent"
                height: queuelist.normalHeight
                objectName: "nowPlayingListItem" + index
                state: queuelist.currentIndex == index && !reordering ? "current" : ""

                leftSideAction: Remove {
                    onTriggered: {
                        if (queuelist.count === 1) {
                            player.stop()
                            musicToolbar.goBack()
                        } else if (index === player.currentIndex) {
                            player.nextSong(player.isPlaying);
                        }

                        if (index < player.currentIndex) {
                            // update index as the old has been removed
                            player.currentIndex -= 1;
                        }

                        queuelist.model.remove(index);
                    }
                }
                reorderable: true
                rightSideActions: [
                    AddToPlaylist{

                    }
                ]
                triggerActionOnMouseRelease: true

                onItemClicked: {
                    customdebug("File: " + model.filename) // debugger
                    trackQueueClick(index);  // toggle track state
                }
                onReorder: {
                    console.debug("Move: ", from, to);

                    queuelist.model.move(from, to, 1);


                    // Maintain currentIndex with current song
                    if (from === player.currentIndex) {
                        player.currentIndex = to;
                    }
                    else if (from < player.currentIndex && to >= player.currentIndex) {
                        player.currentIndex -= 1;
                    }
                    else if (from > player.currentIndex && to <= player.currentIndex) {
                        player.currentIndex += 1;
                    }
                }

                // TODO: If http://pad.lv/1354753 is fixed to expose whether the Shape should appear pressed, update this as well.
                onPressedChanged: trackImage.pressed = pressed

                Rectangle {
                    id: trackContainer;
                    anchors {
                        fill: parent
                        margins: units.gu(1)
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

                    CoverRow {
                        id: trackImage

                        anchors {
                            top: parent.top
                            left: parent.left
                            leftMargin: units.gu(1.5)
                        }
                        count: 1
                        size: (queueListItem.state === "current"
                               ? (mainView.wideAspect
                                  ? queuelist.currentHeight
                                  : mainView.width - (trackImage.anchors.leftMargin * 2))
                               : queuelist.normalHeight) - units.gu(2)
                        covers: [{author: model.author, album: model.album}]

                        spacing: units.gu(2)

                        Item {  // Background so can see text in current state
                            id: albumBg
                            visible: false
                            anchors {
                                bottom: parent.bottom
                                left: parent.left
                                right: parent.right
                            }
                            height: units.gu(9)
                            clip: true
                            UbuntuShape{
                                anchors {
                                    bottom: parent.bottom
                                    left: parent.left
                                    right: parent.right
                                }
                                height: trackImage.height
                                radius: "medium"
                                color: styleMusic.common.black
                                opacity: 0.6
                            }
                        }

                        function calcAnchors() {
                            if (trackImage.height > queuelist.normalHeight && mainView.wideAspect) {
                                trackImage.anchors.left = undefined
                                trackImage.anchors.horizontalCenter = trackImage.parent.horizontalCenter
                            } else {
                                trackImage.anchors.left = trackImage.parent.left
                                trackImage.anchors.horizontalCenter = undefined
                            }

                            trackImage.width = trackImage.height;  // force width to match height
                        }

                        Connections {
                            target: mainView
                            onWideAspectChanged: trackImage.calcAnchors()
                        }

                        onHeightChanged: {
                            calcAnchors()
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
                        text: model.author
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
                        text: model.title
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
                        text: model.album
                        fontSize: 'x-small'
                        width: parent.width - trackImage.width - units.gu(3.5)
                        x: trackImage.x + trackImage.width + units.gu(1)
                        y: nowPlayingTitle.y + nowPlayingTitle.height + units.gu(1.25)
                    }
                }

                states: State {
                    name: "current"
                    PropertyChanges {
                        target: queueListItem
                        height: trackImage.height + (trackContainer.anchors.margins * 2)
                    }
                    PropertyChanges {
                        target: nowPlayingArtist
                        width: trackImage.width - units.gu(4)
                        x: trackImage.x + units.gu(2)
                        y: trackImage.y + trackImage.height - albumBg.height + units.gu(1)
                        color: styleMusic.common.white
                    }
                    PropertyChanges {
                        target: nowPlayingTitle
                        width: trackImage.width - units.gu(4)
                        x: trackImage.x + units.gu(2)
                        y: nowPlayingArtist.y + nowPlayingArtist.height + units.gu(1.25)
                        color: styleMusic.common.white
                        font.weight: Font.DemiBold
                    }
                    PropertyChanges {
                        target: nowPlayingAlbum
                        width: trackImage.width - units.gu(4)
                        x: trackImage.x + units.gu(2)
                        y: nowPlayingTitle.y + nowPlayingTitle.height + units.gu(1.25)
                        color: styleMusic.common.white
                    }
                    PropertyChanges {
                        target: albumBg
                        visible: true
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
}
