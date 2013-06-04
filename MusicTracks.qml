/*
 * Copyleft Daniel Holm.
 *
 * Authors:
 *  Daniel Holm <d.holmen@gmail.com>
 *  Victor Thompson <victor.thompson@gmail.com>
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
        filelist.currentIndex = filelistCurrentIndex
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

    Component.onCompleted: {
        pageStack.push(mainpage)
        Settings.initialize()
        console.debug("INITIALIZED")
        if (Settings.getSetting("initialized") !== "true") {
            // initialize settings
            console.debug("reset settings")
            Settings.setSetting("initialized", "true")
            Settings.setSetting("currentfolder", folderModel.homePath() + "/Music")
        }
        random = Settings.getSetting("shuffle") == "1"
        filelist.currentIndex = -1
    }

    Page {
        id: mainpage

        title: i18n.tr("Music")

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
            id: filelist
            width: parent.width
            height: parent.height - units.gu(8)
            anchors.top: tracksContext.bottom
            highlight: highlight
            highlightFollowsCurrentItem: true
            model: folderModel
            delegate: fileDelegate
            onCountChanged: {
                filelistCount = filelist.count
            }
            onCurrentIndexChanged: {
                filelistCurrentIndex = filelist.currentIndex
                console.log("filelist.currentIndex = " + filelist.currentIndex)
            }

            Component {
                id: fileDelegate
                ListItem.Standard {
                    id: file
                    progression: model.isDir
                    icon: !model.isDir ? (trackCover === "" ? (fileName.match("\\.mp3") ? Qt.resolvedUrl("images/audio-x-mpeg.png") : Qt.resolvedUrl("images/audio-x-vorbis+ogg.png")) : "image://cover-art/"+filePath) : Qt.resolvedUrl("images/folder.png")
                    iconFrame: false
                    Label {
                        id: fileTitle
                        width: 400
                        wrapMode: Text.Wrap
                        maximumLineCount: 1
                        font.pixelSize: 16
                        anchors.left: parent.left
                        anchors.leftMargin: 75
                        anchors.top: parent.top
                        anchors.topMargin: 5
                        text: trackTitle == "" ? fileName : trackTitle
                    }
                    Label {
                        id: fileArtistAlbum
                        width: 400
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        font.pixelSize: 12
                        anchors.left: parent.left
                        anchors.leftMargin: 75
                        anchors.top: fileTitle.bottom
                        text: trackArtist == "" ? "" : trackArtist + " - " + trackAlbum
                    }
                    Label {
                        id: fileDuration
                        width: 400
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        font.pixelSize: 12
                        anchors.left: parent.left
                        anchors.leftMargin: 75
                        anchors.top: fileArtistAlbum.bottom
                        visible: false
                        text: ""
                    }

                    onFocusChanged: {
                        if (focus == false) {
                            selected = false
                        } else if (file.progression == false){
                            selected = false
                            fileArtistAlbumBottom.text = fileArtistAlbum.text
                            fileTitleBottom.text = fileTitle.text
                            fileArtistAlbumBottom_nowplaying.text = fileArtistAlbum.text
                            fileTitleBottom_nowplaying.text = fileTitle.text
                            iconbottom.source = file.icon
                            iconbottom_nowplaying.source = !model.isDir && trackCover !== "" ? "image://cover-art-full/" + filePath : "images/Blank_album.jpg"
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onDoubleClicked: {
                        }
                        onPressAndHold: {
                            if (!model.isDir) {
                                trackQueue.append({"title": trackTitle, "artist": trackArtist, "file": filePath})
                            }
                        }
                        onClicked: {
                            if (focus == false) {
                                focus = true
                            }
                            if (model.isDir) {
                                PlayingList.clear()
                                filelist.currentIndex = -1
                                itemnum = 0
                                playing = filelist.currentIndex
                                console.log("Stored:" + Settings.getSetting("currentfolder"))
                                folderModel.path = filePath
                            } else {
                                console.log("fileName: " + fileName)
                                if (filelist.currentIndex == index) {
                                    if (player.playbackState === MediaPlayer.PlayingState)  {
                                        playindicator.source = "images/play.png"
                                        player.pause()
                                    } else if (player.playbackState === MediaPlayer.PausedState) {
                                        playindicator.source = "images/pause.png"
                                        player.play()
                                    }
                                } else {
                                    player.stop()
                                    player.source = Qt.resolvedUrl(filePath)
                                    filelist.currentIndex = index
                                    playing = PlayingList.indexOf(filePath)
                                    console.log("Playing click: "+player.source)
                                    console.log("Index: " + filelist.currentIndex)
                                    player.play()
                                    playindicator.source = "images/pause.png"
                                }
                                console.log("Source: " + player.source.toString())
                                console.log("Length: " + trackLength.toString())
                            }
                            playindicator_nowplaying.source = playindicator.source
                        }
                    }
                    Component.onCompleted: {
                        if (!PlayingList.contains(filePath) && !model.isDir) {
                            console.log("Adding file:" + filePath)
                            PlayingList.addItem(filePath, itemnum)
                            console.log(itemnum)
                        }
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
            anchors.top: filelist.bottom
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
                        id: upindicator_nowplaying
                        source: "images/back.png"
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        opacity: .7
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            getSong(-1)
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
                        onClicked: {
                            pageStack.pop(nowPlaying)
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
                    maximumLineCount: 1
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
