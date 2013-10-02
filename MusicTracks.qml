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
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import "settings.js" as Settings
import "meta-database.js" as Library
import "playlists.js" as Playlists


PageStack {
    id: pageStack
    anchors.fill: parent

    MusicSettings {
        id: musicSettings
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
                    console.debug('Debug: Show settings from tracks')
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

        ListView {
            id: tracklist
            width: parent.width
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.bottomMargin: units.gu(8)
            highlightFollowsCurrentItem: false
            model: libraryModel.model
            delegate: trackDelegate
            onCountChanged: {
                //customdebug("onCountChanged: " + tracklist.count) // activate later
                tracklist.currentIndex = libraryModel.indexOf(currentFile)
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
                    width: parent.width
                    height: styleMusic.common.itemHeight

                    UbuntuShape {
                        id: trackCover
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(1)
                        anchors.top: parent.top
                        anchors.topMargin: units.gu(1)
                        width: styleMusic.common.albumSize
                        height: styleMusic.common.albumSize
                        image: Image {
                            source: cover !== "" ? cover : Qt.resolvedUrl("images/cover_default_icon.png")
                        }
                    }
                    Label {
                        id: trackTitle
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                        fontSize: "medium"
                        anchors.left: trackCover.left
                        anchors.leftMargin: units.gu(12)
                        anchors.top: parent.top
                        anchors.topMargin: units.gu(1)
                        text: track.title == "" ? track.file : track.title
                    }
                    Label {
                        id: trackArtistAlbum
                        wrapMode: Text.NoWrap
                        maximumLineCount: 2
                        fontSize: "small"
                        anchors.left: trackCover.left
                        anchors.leftMargin: units.gu(12)
                        anchors.top: trackTitle.bottom
                        text: artist == "" ? "" : artist + " - " + album
                    }
                    Label {
                        id: trackDuration
                        wrapMode: Text.NoWrap
                        maximumLineCount: 2
                        fontSize: "small"
                        anchors.left: trackCover.left
                        anchors.leftMargin: units.gu(12)
                        anchors.top: trackArtistAlbum.bottom
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
                            chosenAlbum = album
                            chosenCover = cover
                            chosenGenre = genre
                            chosenIndex = index
                        }
                        onClicked: {
                            if (focus == false) {
                                focus = true
                            }

                            trackClicked(libraryModel, index)  // play track
                        }
                    }
                    Component.onCompleted: {
                        // Set first track as current track
                        if (trackQueue.model.count === 0 && !argFile) {
                            trackClicked(libraryModel, index, false)
                        }

                        console.log("Title:" + title + " Artist: " + artist)
                    }
                    states: State {
                        name: "Current"
                        when: track.ListView.isCurrentItem
                    }
                }
            }
        }
    }
}
