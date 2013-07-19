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

    property int filelistCurrentIndex: 0
    property int filelistCount: 0

    onFilelistCurrentIndexChanged: {
        tracklist.currentIndex = filelistCurrentIndex
    }

    Page {
        id: mainpage

        tools: ToolbarItems {
            // Settings dialog
            ToolbarButton {
                objectName: "settingsaction"
                iconSource: Qt.resolvedUrl("images/settings.png")
                text: i18n.tr("Settings")

                onTriggered: {
                    console.debug('Debug: Show settings')
                    PopupUtils.open(Qt.resolvedUrl("MusicSettings.qml"), mainView,
                                    {
                                        title: i18n.tr("Settings")
                                    } )
                }
            }
        }

        title: i18n.tr("Music")
        Component.onCompleted: {
            pageStack.push(mainpage)
        }

        Component {
            id: highlight
            Rectangle {
                width: 5; height: 40
                color: "#FFFFFF";
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
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                        fontSize: "medium"
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(8)
                        anchors.top: parent.top
                        anchors.topMargin: 5
                        anchors.right: parent.right
                        text: track.title == "" ? track.file : track.title
                    }
                    Label {
                        id: trackArtistAlbum
                        wrapMode: Text.NoWrap
                        maximumLineCount: 2
                        fontSize: "small"
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(8)
                        anchors.top: trackTitle.bottom
                        anchors.right: parent.right
                        text: artist == "" ? "" : artist + " - " + album
                    }
                    Label {
                        id: trackDuration
                        wrapMode: Text.NoWrap
                        maximumLineCount: 2
                        fontSize: "small"
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(8)
                        anchors.top: trackArtistAlbum.bottom
                        anchors.right: parent.right
                        visible: false
                        text: ""
                    }

                    onFocusChanged: {
                    }
                    MouseArea {
                        anchors.fill: parent
                        onDoubleClicked: {
                        }
                        onPressAndHold: {
                            PopupUtils.open(trackPopoverComponent, mainView)
                            chosenArtist = artist
                            chosenTitle = title
                            chosenTrack = file
                        }
                        onClicked: {
                            if (focus == false) {
                                focus = true
                            }

                            tracklist.currentIndex = index
                            trackClicked(file, index, libraryModel.model, tracklist)
                        }
                    }
                    Component.onCompleted: {
                        if (PlayingList.size() === 0) {
                            player.source = file
                            currentModel = libraryModel.model
                            currentListView = tracklist
                            currentIndex = 0
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
