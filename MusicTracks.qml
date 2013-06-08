/*
 * Copyright (C) 2013 Victor Thompson <victor.thompson@gmail.com>
 *                    Daniel Holm <d.holmen@gmail.com>
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
import "playing-list.js" as PlayingList



PageStack {
    id: pageStack
    anchors.fill: parent

    property bool needsUpdate: false
    property int filelistCurrentIndex: 0
    property int filelistCount: 0

    onFilelistCurrentIndexChanged: {
        tracklist.currentIndex = filelistCurrentIndex
    }

    onNeedsUpdateChanged: {
        if (needsUpdate === true) {
            needsUpdate = false
            fileDurationProgressBackground.visible = true
            fileDurationProgressBackground_nowplaying.visible = true
            fileDurationProgress.width = units.gu(Math.floor((player.position*100)/player.duration) * .2) // 20 max
            fileDurationProgress_nowplaying.width = units.gu(Math.floor((player.position*100)/player.duration) * .4) // 40 max
            fileDurationBottom.text = Math.floor((player.position/1000) / 60).toString() + ":" + (
                        Math.floor((player.position/1000) % 60)<10 ? "0"+Math.floor((player.position/1000) % 60).toString() :
                                                          Math.floor((player.position/1000) % 60).toString())
            fileDurationBottom.text += " / "
            fileDurationBottom.text += Math.floor((player.duration/1000) / 60).toString() + ":" + (
                        Math.floor((player.duration/1000) % 60)<10 ? "0"+Math.floor((player.duration/1000) % 60).toString() :
                                                          Math.floor((player.duration/1000) % 60).toString())
            fileDurationBottom_nowplaying.text = fileDurationBottom.text
        }
    }

    Page {
        id: mainpage

        title: i18n.tr("Music")
        Component.onCompleted: {
            pageStack.push(mainpage)
            Settings.initialize()
            Library.initialize()
            console.debug("INITIALIZED")
            if (Settings.getSetting("initialized") !== "true") {
                // initialize settings
                console.debug("reset settings")
                Settings.setSetting("initialized", "true")
                Settings.setSetting("currentfolder", folderModel.homePath() + "/Music")
            }
            random = Settings.getSetting("shuffle") == "1"
        }

        Component {
            id: highlight
            Rectangle {
                width: 5; height: 40
                color: "#DD4814";
                Behavior on y {
                    SpringAnimation {
                        spring: 3
                        damping: 0.2
                    }
                }
            }
        }

        ListView {
            id: tracklist
            width: parent.width
            anchors.top: appContext.bottom
            anchors.bottom: playerControls.top
            highlight: highlight
            highlightFollowsCurrentItem: true
            model: libraryModel.model
            delegate: trackDelegate
            onCountChanged: {
                console.log("onCountChanged: " + tracklist.count)
                filelistCount = tracklist.count
            }
            onCurrentIndexChanged: {
                filelistCurrentIndex = tracklist.currentIndex
                console.log("tracklist.currentIndex = " + tracklist.currentIndex)
            }
            onModelChanged: {
                console.log("PlayingList cleared")
                PlayingList.clear()
            }

            Component {
                id: trackDelegate
                ListItem.Standard {
                    id: track
                    property string artist: model.artist
                    property string album: model.album
                    property string title: model.title
                    property string cover: model.cover
                    property string length: model.length
                    property string file: model.file
                    icon: cover === "" ? (file.match("\\.mp3") ? Qt.resolvedUrl("images/audio-x-mpeg.png") : Qt.resolvedUrl("images/audio-x-vorbis+ogg.png")) : "image://cover-art/"+file
                    iconFrame: false
                    Label {
                        id: trackTitle
                        width: 400
                        wrapMode: Text.Wrap
                        maximumLineCount: 1
                        font.pixelSize: 16
                        anchors.left: parent.left
                        anchors.leftMargin: 75
                        anchors.top: parent.top
                        anchors.topMargin: 5
                        text: track.title == "" ? track.file : track.title
                    }
                    Label {
                        id: trackArtistAlbum
                        width: 400
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        font.pixelSize: 12
                        anchors.left: parent.left
                        anchors.leftMargin: 75
                        anchors.top: trackTitle.bottom
                        text: artist == "" ? "" : artist + " - " + album
                    }
                    Label {
                        id: trackDuration
                        width: 400
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        font.pixelSize: 12
                        anchors.left: parent.left
                        anchors.leftMargin: 75
                        anchors.top: trackArtistAlbum.bottom
                        visible: false
                        text: ""
                    }

                    onFocusChanged: {
                        if (focus == false) {
                            selected = false
                        } else {
                            selected = false
                            fileArtistAlbumBottom.text = trackArtistAlbum.text
                            fileTitleBottom.text = trackTitle.text
                            fileArtistAlbumBottom_nowplaying.text = artist == "" ? "" : artist + "\n" + album
                            fileTitleBottom_nowplaying.text = trackTitle.text
                            iconbottom.source = track.icon
                            iconbottom_nowplaying.source = cover !== "" ? "image://cover-art-full/" + file : "images/Blank_album.jpg"
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onDoubleClicked: {
                        }
                        onPressAndHold: {
                            trackQueue.append({"title": title, "artist": artist, "file": file})
                        }
                        onClicked: {
                            if (focus == false) {
                                focus = true
                            }
                            console.log("fileName: " + file)
                            if (tracklist.currentIndex == index) {
                                if (player.playbackState === MediaPlayer.PlayingState)  {
                                    playindicator.source = "images/play.png"
                                    player.pause()
                                } else if (player.playbackState === MediaPlayer.PausedState) {
                                    playindicator.source = "images/pause.png"
                                    player.play()
                                }
                            } else {
                                player.stop()
                                player.source = Qt.resolvedUrl(file)
                                tracklist.currentIndex = index
                                playing = PlayingList.indexOf(file)
                                console.log("Playing click: "+player.source)
                                console.log("Index: " + tracklist.currentIndex)
                                player.play()
                                playindicator.source = "images/pause.png"
                            }
                            console.log("Source: " + player.source.toString())
                            console.log("Length: " + length.toString())
                            playindicator_nowplaying.source = playindicator.source
                        }
                    }
                    Component.onCompleted: {
                        if (PlayingList.size() === 0) {
                            player.source = file
                        }

                        if (!PlayingList.contains(file)) {
                            console.log("Adding file:" + file)
                            PlayingList.addItem(file, itemnum)
                            console.log(itemnum)
                        }
                        console.log("Title:" + title + " Artist: " + artist)
                        itemnum++
                    }
                }
            }
        }

        // context: albums? tracks?
        Rectangle {
            id: appContext
            anchors.top: mainpage.top
            height: units.gu(5)
            width: parent.width
            color: "#333333"
            MouseArea {
                id: tracksContextArea
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                width: units.gu(10)
                height: units.gu(5)
                onClicked: {
                    tracksContext.font.underline = true
                    artistsContext.font.underline = false
                    albumsContext.font.underline = false
                    listsContext.font.underline = false
                    player.stop()
                    libraryModel.populate()
                }
                Label {
                    id: tracksContext
                    width: units.gu(15)
                    wrapMode: Text.Wrap
                    color: "#FFFFFF"
                    maximumLineCount: 1
                    font.pixelSize: 20
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(1)
                    text: "Music"
                    font.underline: true
                }
            }
            MouseArea {
                id: artistsContextArea
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: tracksContextArea.right
                width: units.gu(10)
                height: units.gu(5)
                onClicked: {
                    tracksContext.font.underline = false
                    artistsContext.font.underline = true
                    albumsContext.font.underline = false
                    listsContext.font.underline = false
                    player.stop()
                    libraryModel.filterArtists()
                }
                Label {
                    id: artistsContext
                    width: units.gu(10)
                    wrapMode: Text.Wrap
                    color: "#FFFFFF"
                    maximumLineCount: 1
                    font.pixelSize: 20
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    text: "Artists"
                }
            }
            MouseArea {
                id: albumsContextArea
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: artistsContextArea.right
                width: units.gu(10)
                height: units.gu(5)
                onClicked: {
                    tracksContext.font.underline = false
                    artistsContext.font.underline = false
                    albumsContext.font.underline = true
                    listsContext.font.underline = false
                    player.stop()
                    libraryModel.filterAlbums()
                }
                Label {
                    id: albumsContext
                    width: units.gu(15)
                    wrapMode: Text.Wrap
                    color: "#FFFFFF"
                    maximumLineCount: 1
                    font.pixelSize: 20
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    text: "Albums"
                }
            }
            MouseArea {
                id: listsContextArea
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: albumsContextArea.right
                width: units.gu(10)
                height: units.gu(5)
                onClicked: {

                    PopupUtils.open(Qt.resolvedUrl("QueueDialog.qml"), settingsArea,
                                {
                                    title: i18n.tr("Queue")
                                } )
                }
                Label {
                    id: listsContext
                    width: units.gu(15)
                    wrapMode: Text.Wrap
                    color: "#FFFFFF"
                    maximumLineCount: 1
                    font.pixelSize: 20
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    text: "Queue"
                }
            }
            MouseArea {
                id: settingsArea
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: listsContextArea.right
                anchors.right: parent.right
                height: units.gu(5)
                onClicked: {
                    PopupUtils.open(Qt.resolvedUrl("MusicSettings.qml"), settingsArea,
                                {
                                    title: i18n.tr("Settings")
                                } )
                }
                Image {
                    id: settingsImage
                    source: "images/settings.png"
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: units.gu(1)
                }
            }

        }

        Rectangle {
            id: playerControls
            anchors.bottom: parent.bottom
            //anchors.top: filelist.bottom
            height: units.gu(8)
            width: parent.width
            color: "#333333"
            UbuntuShape {
                id: forwardshape
                height: units.gu(5)
                width: units.gu(5)
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: units.gu(2)
                radius: "none"
                image: Image {
                    id: forwardindicator
                    source: "images/forward.png"
                    anchors.right: parent.right
                    anchors.centerIn: parent
                    opacity: .7
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        playindicator.source = "images/pause.png"
                        playindicator_nowplaying.source = playindicator.source
                        nextSong()
                    }
                }
            }
            UbuntuShape {
                id: playshape
                height: units.gu(5)
                width: units.gu(5)
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: forwardshape.left
                anchors.rightMargin: units.gu(1)
                radius: "none"
                image: Image {
                    id: playindicator
                    source: "images/play.png"
                    anchors.right: parent.right
                    anchors.centerIn: parent
                    opacity: .7
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (player.playbackState === MediaPlayer.PlayingState)  {
                            playindicator.source = "images/play.png"
                            player.pause()
                        } else {
                            playindicator.source = "images/pause.png"
                            player.play()
                        }
                        playindicator_nowplaying.source = playindicator.source
                    }
                }
            }
            Image {
                id: iconbottom
                source: ""
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.topMargin: units.gu(1)
                anchors.leftMargin: units.gu(1)

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        pageStack.push(nowPlaying)
                    }
                }
            }
            Label {
                id: fileTitleBottom
                width: units.gu(30)
                wrapMode: Text.Wrap
                color: "#FFFFFF"
                maximumLineCount: 1
                font.pixelSize: 16
                anchors.left: iconbottom.right
                anchors.top: parent.top
                anchors.topMargin: units.gu(1)
                anchors.leftMargin: units.gu(1)
                text: ""
            }
            Label {
                id: fileArtistAlbumBottom
                width: units.gu(30)
                wrapMode: Text.Wrap
                color: "#FFFFFF"
                maximumLineCount: 1
                font.pixelSize: 12
                anchors.left: iconbottom.right
                anchors.top: fileTitleBottom.bottom
                anchors.leftMargin: units.gu(1)
                text: ""
            }
            Rectangle {
                id: fileDurationProgressContainer
                anchors.top: fileArtistAlbumBottom.bottom
                anchors.left: iconbottom.right
                anchors.topMargin: 2
                anchors.leftMargin: units.gu(1)
                width: units.gu(20)
                color: "#333333"

                Rectangle {
                    id: fileDurationProgressBackground
                    anchors.top: parent.top
                    anchors.topMargin: 2
                    height: 1
                    width: units.gu(20)
                    color: "#FFFFFF"
                    visible: false
                }
                Rectangle {
                    id: fileDurationProgress
                    anchors.top: parent.top
                    height: 5
                    width: 0
                    color: "#DD4814"
                }
            }
            Label {
                id: fileDurationBottom
                anchors.top: fileArtistAlbumBottom.bottom
                anchors.left: fileDurationProgressContainer.right
                anchors.leftMargin: units.gu(1)
                width: units.gu(30)
                wrapMode: Text.Wrap
                color: "#FFFFFF"
                maximumLineCount: 1
                font.pixelSize: 12
                text: ""
            }
        }
    }

    Page {
        id: nowPlaying
        visible: false

        Rectangle {
            anchors.fill: parent
            height: units.gu(10)
            color: "#333333"
            Column {
                anchors.fill: parent
                anchors.bottomMargin: units.gu(10)

                UbuntuShape {
                    id: forwardshape_nowplaying
                    height: 50
                    width: 50
                    anchors.bottom: parent.bottom
                    anchors.left: playshape_nowplaying.right
                    anchors.leftMargin: units.gu(2)
                    radius: "none"
                    image: Image {
                        id: forwardindicator_nowplaying
                        source: "images/forward.png"
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        opacity: .7
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            playindicator.source = "images/pause.png"
                            playindicator_nowplaying.source = playindicator.source
                            nextSong()
                        }
                    }
                }
                UbuntuShape {
                    id: playshape_nowplaying
                    height: 50
                    width: 50
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: "none"
                    image: Image {
                        id: playindicator_nowplaying
                        source: "images/play.png"
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        opacity: .7
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (player.playbackState === MediaPlayer.PlayingState)  {
                                playindicator.source = "images/play.png"
                                player.pause()
                            } else {
                                playindicator.source = "images/pause.png"
                                player.play()
                            }
                            playindicator_nowplaying.source = playindicator.source
                        }
                    }
                }
                UbuntuShape {
                    id: backshape_nowplaying
                    height: 50
                    width: 50
                    anchors.bottom: parent.bottom
                    anchors.right: playshape_nowplaying.left
                    anchors.rightMargin: units.gu(2)
                    radius: "none"
                    image: Image {
                        id: backindicator_nowplaying
                        source: "images/back.png"
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        opacity: .7
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            playindicator.source = "images/pause.png"
                            playindicator_nowplaying.source = playindicator.source
                            previousSong()
                        }
                    }
                }

                Image {
                    id: iconbottom_nowplaying
                    source: ""
                    width: 300
                    height: 300
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(1)
                    anchors.leftMargin: units.gu(1)

                    MouseArea {
                        anchors.fill: parent
                        signal swipeRight;
                        signal swipeLeft;
                        signal swipeUp;
                        signal swipeDown;

                        property int startX;
                        property int startY;

                        onPressed: {
                            startX = mouse.x;
                            startY = mouse.y;
                        }

                        onReleased: {
                            var deltax = mouse.x - startX;
                            var deltay = mouse.y - startY;

                            if (Math.abs(deltax) > 50 || Math.abs(deltay) > 50) {
                                if (deltax > 30 && Math.abs(deltay) < 30) {
                                    // swipe right
                                    previousSong();
                                } else if (deltax < -30 && Math.abs(deltay) < 30) {
                                    // swipe left
                                    nextSong();
                                }
                            } else {
                                pageStack.pop(nowPlaying)
                            }
                        }
                    }
                }
                Label {
                    id: fileTitleBottom_nowplaying
                    width: units.gu(30)
                    wrapMode: Text.Wrap
                    color: "#FFFFFF"
                    maximumLineCount: 1
                    font.pixelSize: 24
                    anchors.top: iconbottom_nowplaying.bottom
                    anchors.topMargin: units.gu(2)
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(2)
                    text: ""
                }
                Label {
                    id: fileArtistAlbumBottom_nowplaying
                    width: units.gu(30)
                    wrapMode: Text.Wrap
                    color: "#FFFFFF"
                    maximumLineCount: 2
                    font.pixelSize: 16
                    anchors.left: parent.left
                    anchors.top: fileTitleBottom_nowplaying.bottom
                    anchors.leftMargin: units.gu(2)
                    text: ""
                }
                Rectangle {
                    id: fileDurationProgressContainer_nowplaying
                    anchors.top: fileArtistAlbumBottom_nowplaying.bottom
                    anchors.left: parent.left
                    anchors.topMargin: units.gu(2)
                    anchors.leftMargin: units.gu(2)
                    width: units.gu(40)
                    color: "#333333"

                    Rectangle {
                        id: fileDurationProgressBackground_nowplaying
                        anchors.top: parent.top
                        anchors.topMargin: 4
                        height: 1
                        width: units.gu(40)
                        color: "#FFFFFF"
                        visible: false
                    }
                    Rectangle {
                        id: fileDurationProgress_nowplaying
                        anchors.top: parent.top
                        height: 8
                        width: 0
                        color: "#DD4814"
                    }
                }
                Label {
                    id: fileDurationBottom_nowplaying
                    anchors.top: fileDurationProgressContainer_nowplaying.bottom
                    anchors.left: parent.left
                    anchors.topMargin: units.gu(2)
                    anchors.leftMargin: units.gu(2)
                    width: units.gu(30)
                    wrapMode: Text.Wrap
                    color: "#FFFFFF"
                    maximumLineCount: 1
                    font.pixelSize: 16
                    text: ""
                }
            }
        }
    }
}
