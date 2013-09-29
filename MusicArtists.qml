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

        onVisibleChanged: {
            if (visible === true)
            {
                musicToolbar.setPage(mainpage);
            }
        }

        Component.onCompleted: {
            pageStack.push(mainpage)
            onPlayingTrackChange.connect(updateHighlight)
        }

        function updateHighlight(file)
        {
            console.debug("MusicArtists update highlight:", file)
            artisttrackslist.currentIndex = artistTracksModel.indexOf(file)
        }

        ListView {
            id: artistlist
            anchors.fill: parent
            anchors.bottomMargin: musicToolbar.mouseAreaOffset + musicToolbar.minimizedHeight
            model: artistModel.model
            delegate: artistDelegate

            Component {
                id: artistDelegate

                ListItem.Standard {
                    id: track
                    property string artist: model.artist
                    icon: cover !== "" ? cover : Qt.resolvedUrl("images/cover_default_icon.png")

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
        tools: null
        visible: false

        onVisibleChanged: {
            if (visible === true)
            {
                musicToolbar.setPage(artistpage, mainpage, pageStack);
            }
        }

        ListView {
            id: artisttrackslist
            clip: true
            property string artist: ""
            property string file: ""
            property string cover: ""
            anchors.fill: parent
            anchors.bottomMargin: musicToolbar.mouseAreaOffset + musicToolbar.minimizedHeight
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
                    text: artistTracksModel.model.count + " songs"
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
