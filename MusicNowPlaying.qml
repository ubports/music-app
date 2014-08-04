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
import QtQuick 2.0
import QtQuick.LocalStorage 2.0
import Ubuntu.Components 0.1
import Ubuntu.Thumbnailer 0.1
import "common"
import "common/ListItemActions"
import "settings.js" as Settings

MusicPage {
    id: nowPlaying
    objectName: "nowplayingpage"
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
        objectName: "queuelist"
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
        property int currentHeight: units.gu(48)
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
                state: queuelist.currentIndex == index && !reordering ? "current" : ""

                leftSideAction: Remove {
                    onItemRemoved: {
                        if (index === player.currentIndex) {
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

                Rectangle {
                    id: trackContainer;
                    anchors {
                        fill: parent
                        margins: units.gu(0.5)
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
                            source: "image://albumart/artist=" + model.author + "&album=" + model.album
                            onStatusChanged: {
                                if (status === Image.Error) {
                                    source = Qt.resolvedUrl("images/music-app-cover@30.png")
                                }
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
}
