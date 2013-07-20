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
import "playlists.js" as Playlists

PageStack {
    id: pageStack
    anchors.fill: parent

    Page {
        id: mainpage
        title: i18n.tr("Artists")
        Component.onCompleted: {
            pageStack.push(mainpage)
        }

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
            id: artistlist
            width: parent.width
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.bottomMargin: units.gu(8)
            model: artistModel.model
            delegate: artistDelegate

            Component {
                id: artistDelegate

                ListItem.Standard {
                    id: track
                    property string artist: model.artist
                    property string cover: model.cover
                    icon: cover === "" ? Qt.resolvedUrl("images/cover_default_icon.png") : "image://cover-art/"+file
                    iconFrame: false
                    progression: true
                    Label {
                        id: trackArtistAlbum
                        wrapMode: Text.NoWrap
                        maximumLineCount: 2
                        fontSize: "large"
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(8)
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        text: artist
                    }

                    onFocusChanged: {
                    }
                    MouseArea {
                        anchors.fill: parent
                        onDoubleClicked: {
                        }
                        onPressAndHold: {
                        }
                        onClicked: {
                            artistTracksModel.filterArtistTracks(artist)
                            pageStack.push(artistpage)
                        }
                    }
                    Component.onCompleted: {
                    }
                }
            }
        }
    }

    Page {
        id: artistpage
        title: i18n.tr("Tracks")

        ListView {
            id: artisttrackslist
            width: parent.width
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.bottomMargin: units.gu(8)
            highlight: highlight
            highlightFollowsCurrentItem: true
            model: artistTracksModel.model
            delegate: artistTracksDelegate

            Component {
                id: artistTracksDelegate

                ListItem.Standard {
                    id: track
                    property string artist: model.artist
                    property string album: model.album
                    property string title: model.title
                    property string cover: model.cover
                    property string length: model.length
                    property string file: model.file
                    icon: cover === "" ? Qt.resolvedUrl("images/cover_default_icon.png") : "image://cover-art/"+file
                    iconFrame: false
                    progression: false
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

                    onFocusChanged: {
                    }
                    MouseArea {
                        anchors.fill: parent
                        onDoubleClicked: {
                        }
                        onPressAndHold: {
                        }
                        onClicked: {
                            if (focus == false) {
                                focus = true
                            }

                            artisttrackslist.currentIndex = index
                            trackClicked(file, index, artistTracksModel.model, artisttrackslist)
                        }
                    }
                    Component.onCompleted: {
                    }
                }
            }
        }
    }



}

