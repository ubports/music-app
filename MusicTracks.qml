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
import "playlists.js" as Playlists


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

        tools: ToolbarActions {
            // Add playlist
            Action {
                id: playlistAction
                objectName: "playlistaction"
                iconSource: Qt.resolvedUrl("images/playlist.png")
                text: i18n.tr("Add Playlist")
                onTriggered: {
                    console.debug("Debug: User pressed add playlist")
                    // show new playlist dialog
                    PopupUtils.open(MusicPlaylists.addPlaylistDialog, mainView)
                }
            }

            // Settings dialog
            Action {
                objectName: "settingsaction"
                iconSource: Qt.resolvedUrl("images/settings@8.png")
                text: i18n.tr("Settings")

                onTriggered: {
                    console.debug('Debug: Show settings')
                    PopupUtils.open(Qt.resolvedUrl("MusicSettings.qml"), mainView,
                                {
                                    title: i18n.tr("Settings")
                                } )
                }
            }

            // Queue dialog
            Action {
                objectName: "queuesaction"
                iconSource: Qt.resolvedUrl("images/folder.png") // change this icon later
                text: i18n.tr("Queue")

                onTriggered: {
                    console.debug('Debug: Show queue')
                    PopupUtils.open(Qt.resolvedUrl("QueueDialog.qml"), mainView,
                                {
                                    title: i18n.tr("Queue")
                                } )
                }
            }
        }

        title: i18n.tr("Music")
        Component.onCompleted: {
            pageStack.push(mainpage)
            Settings.initialize()
            Library.initialize()
            console.debug("INITIALIZED in tracks")
            if (Settings.getSetting("initialized") !== "true") {
                // initialize settings
                console.debug("reset settings")
                Settings.setSetting("initialized", "true") // setting to make sure the DB is there
                //Settings.setSetting("scrobble", "0") // default state of shuffle
                //Settings.setSetting("scrobble", "0") // default state of scrobble
                Settings.setSetting("currentfolder", folderModel.homePath() + "/Music")
            }
            // initialize playlist
            Playlists.initializePlaylists()
            // everything else
            random = Settings.getSetting("shuffle") == "1" // shuffle state
            scrobble = Settings.getSetting("scrobble") == "1" // scrobble state
            lastfmusername = Settings.getSetting("lastfmusername") // lastfm username
            lastfmpassword = Settings.getSetting("lastfmpassword") // lastfm password
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
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.bottomMargin: units.gu(8)
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
                    icon: track.cover === "" ? (track.file.match("\\.mp3") ? Qt.resolvedUrl("images/audio-x-mpeg.png") : Qt.resolvedUrl("images/audio-x-vorbis+ogg.png")) : "image://cover-art/"+file
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
    }
}
