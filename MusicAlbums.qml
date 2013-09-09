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

    MusicSettings {
        id: musicSettings
    }

    Page {
        id: mainpage
        title: i18n.tr("Albums")
        Component.onCompleted: {
            pageStack.push(mainpage)
            onPlayingTrackChange.connect(updateHighlight)
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

        function updateHighlight(file)
        {
            console.debug("MusicArtists update highlight:", file)
            albumtrackslist.currentIndex = albumTracksModel.indexOf(file)
        }

        GridView {
            id: albumlist
            width: parent.width
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            cellHeight: units.gu(18)
            cellWidth: units.gu(14)
            model: albumModel.model
            delegate: albumDelegate

            Component {
                id: albumDelegate
                Item {
                    id: albumItem
                    height: units.gu(17)
                    width: units.gu(13)
                    anchors.margins: units.gu(1)
                    UbuntuShape {
                        id: albumShape
                        height: albumItem.width
                        width: albumItem.width
                        image: Image {
                            id: icon
                            fillMode: Image.Stretch
                            property string artist: model.artist
                            property string album: model.album
                            property string title: model.title
                            property string cover: model.cover
                            property string length: model.length
                            property string file: model.file
                            property string year: model.year
                            source: cover === "" ? Qt.resolvedUrl("images/cover_default.png") : "image://cover-art-full/"+file
                        }
                    }
                    Label {
                        id: albumTitle
                        width: albumItem.width
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        maximumLineCount: 1
                        fontSize: "small"
                        anchors.top: albumShape.bottom
                        anchors.horizontalCenter: albumItem.horizontalCenter
                        text: album
                    }
                    Label {
                        id: albumArtist
                        width: albumItem.width
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        maximumLineCount: 1
                        fontSize: "small"
                        anchors.left: parent.left
                        anchors.top: albumTitle.bottom
                        anchors.horizontalCenter: albumItem.horizontalCenter
                        text: artist
                    }

                    MouseArea {
                        anchors.fill: parent
                        onDoubleClicked: {
                        }
                        onPressAndHold: {
                        }
                        onClicked: {
                            albumTracksModel.filterAlbumTracks(album)
                            albumtrackslist.artist = artist
                            albumtrackslist.album = album
                            albumtrackslist.file = file
                            albumtrackslist.year = year
                            pageStack.push(albumpage)
                        }
                    }
                }
            }
        }
    }

    Page {
        id: albumpage
        title: i18n.tr("Tracks")
        visible: false

        ListView {
            id: albumtrackslist
            clip: true
            property string artist: ""
            property string album: ""
            property string file: ""
            property string year: ""
            width: parent.width
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.bottomMargin: units.gu(8)
            highlightFollowsCurrentItem: false
            model: albumTracksModel.model
            delegate: albumTracksDelegate
            header: ListItem.Standard {
                id: albumInfo
                width: parent.width
                height: units.gu(20)
                UbuntuShape {
                    id: albumImage
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: units.gu(1)
                    height: parent.height
                    width: height
                    image: Image {
                        source: Library.hasCover(albumtrackslist.file) ? "image://cover-art-full/"+albumtrackslist.file : Qt.resolvedUrl("images/cover_default.png")
                    }
                }
                Label {
                    id: albumTitle
                    wrapMode: Text.NoWrap
                    maximumLineCount: 1
                    fontSize: "large"
                    anchors.left: albumImage.right
                    anchors.leftMargin: units.gu(1)
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(1)
                    anchors.right: parent.right
                    text: albumtrackslist.title == "" ? albumtrackslist.file : albumtrackslist.album
                }
                Label {
                    id: albumArtist
                    wrapMode: Text.NoWrap
                    maximumLineCount: 1
                    fontSize: "large"
                    anchors.left: albumImage.right
                    anchors.leftMargin: units.gu(1)
                    anchors.top: albumTitle.bottom
                    anchors.topMargin: units.gu(1)
                    anchors.right: parent.right
                    text: albumtrackslist.artist == "" ? "" : albumtrackslist.artist
                }
                Label {
                    id: albumYear
                    wrapMode: Text.NoWrap
                    maximumLineCount: 1
                    fontSize: "medium"
                    anchors.left: albumImage.right
                    anchors.leftMargin: units.gu(1)
                    anchors.top: albumArtist.bottom
                    anchors.topMargin: units.gu(1)
                    anchors.right: parent.right
                    text: albumtrackslist.year
                }
                Label {
                    id: albumCount
                    wrapMode: Text.NoWrap
                    maximumLineCount: 1
                    fontSize: "medium"
                    anchors.left: albumImage.right
                    anchors.leftMargin: units.gu(1)
                    anchors.top: albumYear.bottom
                    anchors.topMargin: units.gu(1)
                    anchors.right: parent.right
                    text: albumTracksModel.model.count + " songs"
                }

            }

            onCountChanged: {
                albumtrackslist.currentIndex = albumTracksModel.indexOf(currentFile)
            }

            Component {
                id: albumTracksDelegate

                ListItem.Standard {
                    id: track
                    property string artist: model.artist
                    property string album: model.album
                    property string title: model.title
                    property string cover: model.cover
                    property string length: model.length
                    property string file: model.file
                    iconFrame: false
                    progression: false
                    Rectangle {
                        id: highlight
                        anchors.left: parent.left
                        visible: false
                        width: units.gu(.75)
                        height: parent.height
                        color: styleMusic.listView.highlightColor;
                    }
                    Label {
                        id: trackTitle
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                        fontSize: "large"
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(2)
                        anchors.top: parent.top
                        anchors.topMargin: units.gu(1.5)
                        anchors.right: parent.right
                        text: track.title == "" ? track.file : track.title
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
                            chosenAlbum = album
                            chosenTitle = title
                            chosenTrack = file
                        }
                        onClicked: {
                            if (focus == false) {
                                focus = true
                            }
                            trackClicked(albumTracksModel, index)  // play track
                        }
                    }
                    Component.onCompleted: {
                    }
                    states: State {
                        name: "Current"
                        when: track.ListView.isCurrentItem
                        PropertyChanges { target: highlight; visible: true }
                    }
                }
            }
        }
    }
}
