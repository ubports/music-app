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
                    height: styleMusic.common.itemHeight

                    UbuntuShape {
                       id: cover0
                       anchors.left: parent.left
                       anchors.leftMargin: units.gu(4)
                       anchors.top: parent.top
                       anchors.topMargin: units.gu(1)
                       width: styleMusic.common.albumSize
                       height: styleMusic.common.albumSize
                       image: Image {
                           source: Library.getArtistCovers(artist).length > 3 ? Library.getArtistCovers(artist)[3] : "images/cover_default.png"
                       }
                       visible: Library.getArtistCovers(artist).length > 3
                    }
                    UbuntuShape {
                       id: cover1
                       anchors.left: parent.left
                       anchors.leftMargin: units.gu(3)
                       anchors.top: parent.top
                       anchors.topMargin: units.gu(1)
                       width: styleMusic.common.albumSize
                       height: styleMusic.common.albumSize
                       image: Image {
                           source: Library.getArtistCovers(artist).length > 2 ? Library.getArtistCovers(artist)[2] : "images/cover_default.png"
                       }
                       visible: Library.getArtistCovers(artist).length > 2
                    }
                    UbuntuShape {
                       id: cover2
                       anchors.left: parent.left
                       anchors.leftMargin: units.gu(2)
                       anchors.top: parent.top
                       anchors.topMargin: units.gu(1)
                       width: styleMusic.common.albumSize
                       height: styleMusic.common.albumSize
                       image: Image {
                           source: Library.getArtistCovers(artist).length > 1 ? Library.getArtistCovers(artist)[1] : "images/cover_default.png"
                       }
                       visible: Library.getArtistCovers(artist).length > 1
                    }
                    UbuntuShape {
                       id: cover3
                       anchors.left: parent.left
                       anchors.leftMargin: units.gu(1)
                       anchors.top: parent.top
                       anchors.topMargin: units.gu(1)
                       width: styleMusic.common.albumSize
                       height: styleMusic.common.albumSize
                       image: Image {
                           source: Library.getArtistCovers(artist).length > 0 ? Library.getArtistCovers(artist)[0] : "images/cover_default.png"
                       }
                    }

                    Label {
                        id: trackArtistAlbum
                        wrapMode: Text.NoWrap
                        maximumLineCount: 2
                        fontSize: "large"
                        anchors.left: cover3.left
                        anchors.leftMargin: units.gu(14)
                        anchors.top: parent.top
                        anchors.topMargin: units.gu(1)
                        anchors.right: parent.right
                        text: artist // !== '' artist : i18n.tr("Unknown Artist") fix this
                    }

                    Label {
                        id: trackArtistAlbums
                        wrapMode: Text.NoWrap
                        maximumLineCount: 2
                        fontSize: "medium"
                        anchors.left: cover3.left
                        anchors.leftMargin: units.gu(14)
                        anchors.top: trackArtistAlbum.bottom
                        anchors.topMargin: units.gu(1)
                        anchors.right: parent.right
                        text: Library.getArtistCovers(artist).length + i18n.tr(" albums") // model for number of albums?
                    }

                    Label {
                        id: trackArtistAlbumTracks
                        wrapMode: Text.NoWrap
                        maximumLineCount: 2
                        fontSize: "medium"
                        anchors.left: cover3.left
                        anchors.leftMargin: units.gu(14)
                        anchors.top: trackArtistAlbums.bottom
                        anchors.topMargin: units.gu(1)
                        anchors.right: parent.right
                        text: Library.getArtistTracks(artist).length + i18n.tr(" songs") //fix
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
                            artisttrackslist.artist = artist
                            artisttrackslist.file = file
                            artisttrackslist.cover = cover
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
        visible: false

        ListView {
            id: artisttrackslist
            clip: true
            property string artist: ""
            property string file: ""
            property string cover: ""
            width: parent.width
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.bottomMargin: units.gu(8)
            highlightFollowsCurrentItem: false
            model: artistTracksModel.model
            delegate: artistTracksDelegate
            header: ListItem.Standard {
                id: albumInfo
                width: parent.width
                height: units.gu(20)
                UbuntuShape {
                    id: artistImage
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: units.gu(1)
                    height: parent.height
                    width: height
                    image: Image {
                        source: artisttrackslist.cover !== "" ? artisttrackslist.cover : "images/cover_default.png"
                    }
                }
                Label {
                    id: albumArtist
                    wrapMode: Text.NoWrap
                    maximumLineCount: 1
                    fontSize: "large"
                    anchors.left: artistImage.right
                    anchors.leftMargin: units.gu(1)
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(1)
                    anchors.right: parent.right
                    text: artisttrackslist.artist == "" ? "" : artisttrackslist.artist
                }
                Label {
                    id: albumCount
                    wrapMode: Text.NoWrap
                    maximumLineCount: 1
                    fontSize: "medium"
                    anchors.left: artistImage.right
                    anchors.leftMargin: units.gu(1)
                    anchors.top: albumArtist.bottom
                    anchors.topMargin: units.gu(1)
                    anchors.right: parent.right
                    text: artistTracksModel.model.count + i18n.tr(" songs")
                }
            }

            onCountChanged: {
                artisttrackslist.currentIndex = artistTracksModel.indexOf(currentFile)
            }

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
                    icon: cover !== "" ? cover : Qt.resolvedUrl("images/cover_default_icon.png")
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
                        anchors.leftMargin: units.gu(8)
                        anchors.top: parent.top
                        anchors.right: parent.right
                        text: track.title == "" ? track.file : track.title
                    }
                    Label {
                        id: trackAlbum
                        wrapMode: Text.NoWrap
                        maximumLineCount: 2
                        fontSize: "small"
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(8)
                        anchors.top: trackTitle.bottom
                        anchors.right: parent.right
                        text: artist == "" ? "" : album
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
                            chosenCover = cover
                            chosenGenre = genre
                        }
                        onClicked: {
                            if (focus == false) {
                                focus = true
                            }
                            trackClicked(artistTracksModel, index)  // play track
                        }
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

