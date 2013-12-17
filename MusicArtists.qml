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
                           source: Library.getArtistCovers(artist).length > 3 && Library.getArtistCovers(artist)[3] !== "" ? Library.getArtistCovers(artist)[3] : "images/cover_default.png"
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
                           source: Library.getArtistCovers(artist).length > 2 && Library.getArtistCovers(artist)[2] !== "" ? Library.getArtistCovers(artist)[2] : "images/cover_default.png"
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
                           source: Library.getArtistCovers(artist).length > 1 && Library.getArtistCovers(artist)[1] !== "" ? Library.getArtistCovers(artist)[1] : "images/cover_default.png"
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
                           source: Library.getArtistCovers(artist).length > 0 && Library.getArtistCovers(artist)[0] !== "" ? Library.getArtistCovers(artist)[0] : "images/cover_default.png"
                       }
                    }

                    Label {
                        id: trackArtistAlbum
                        wrapMode: Text.NoWrap
                        maximumLineCount: 2
                        fontSize: "medium"
                        color: styleMusic.common.music
                        anchors.left: cover3.left
                        anchors.leftMargin: units.gu(14)
                        anchors.top: parent.top
                        anchors.topMargin: units.gu(2)
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1.5)
                        elide: Text.ElideRight
                        text: artist || i18n.tr("Unknown")
                    }

                    Label {
                        id: trackArtistAlbums
                        wrapMode: Text.NoWrap
                        maximumLineCount: 2
                        fontSize: "x-small"
                        anchors.left: cover3.left
                        anchors.leftMargin: units.gu(14)
                        anchors.top: trackArtistAlbum.bottom
                        anchors.topMargin: units.gu(1)
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1.5)
                        elide: Text.ElideRight
                        // model for number of albums?
                        text: i18n.tr("%1 album", "%1 albums", Library.getArtistAlbumCount(artist)).arg(Library.getArtistAlbumCount(artist))
                    }

                    Label {
                        id: trackArtistAlbumTracks
                        wrapMode: Text.NoWrap
                        maximumLineCount: 2
                        fontSize: "x-small"
                        anchors.left: cover3.left
                        anchors.leftMargin: units.gu(14)
                        anchors.top: trackArtistAlbums.bottom
                        anchors.topMargin: units.gu(1)
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1.5)
                        elide: Text.ElideRight
                        text: i18n.tr("%1 song", "%1 songs", Library.getArtistTracks(artist).length).arg(Library.getArtistTracks(artist).length)
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
                    anchors.margins: units.gu(2)
                    height: parent.height
                    width: height
                    image: Image {
                        source: artisttrackslist.cover !== "" ? artisttrackslist.cover : "images/cover_default.png"
                    }
                }
                Label {
                    id: albumCount
                    wrapMode: Text.NoWrap
                    maximumLineCount: 1
                    fontSize: "small"
                    anchors.left: artistImage.right
                    anchors.leftMargin: units.gu(1)
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(3)
                    anchors.right: parent.right
                    anchors.rightMargin: units.gu(1.5)
                    elide: Text.ElideRight
                    text: i18n.tr("%1 song", "%1 songs", artistTracksModel.model.count).arg(artistTracksModel.model.count)
                }
                Label {
                    id: albumArtist
                    wrapMode: Text.NoWrap
                    maximumLineCount: 1
                    fontSize: "medium"
                    color: styleMusic.common.music
                    anchors.left: artistImage.right
                    anchors.leftMargin: units.gu(1)
                    anchors.top: albumCount.bottom
                    anchors.topMargin: units.gu(1)
                    anchors.right: parent.right
                    anchors.rightMargin: units.gu(1.5)
                    elide: Text.ElideRight
                    text: artisttrackslist.artist == "" ? "" : artisttrackslist.artist
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
                    progression: false
                    height: styleMusic.artists.itemHeight
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
                    UbuntuShape {
                        id: trackCover
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(2)
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
                        fontSize: "small"
                        color: styleMusic.common.music
                        anchors.left: trackCover.right
                        anchors.leftMargin: units.gu(2)
                        anchors.top: trackCover.top
                        anchors.topMargin: units.gu(2)
                        anchors.right: expandItem.left
                        anchors.rightMargin: units.gu(1.5)
                        elide: Text.ElideRight
                        text: track.title == "" ? track.file : track.title
                    }
                    Label {
                        id: trackAlbum
                        wrapMode: Text.NoWrap
                        maximumLineCount: 2
                        fontSize: "x-small"
                        anchors.left: trackCover.right
                        anchors.leftMargin: units.gu(2)
                        anchors.top: trackTitle.bottom
                        anchors.topMargin: units.gu(2)
                        anchors.right: expandItem.left
                        anchors.rightMargin: units.gu(1.5)
                        elide: Text.ElideRight
                        text: album
                    }
                    Image {
                        id: expandItem
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(2)
                        source: expandable.visible ? "images/dropdown-menu-up.svg" : "images/dropdown-menu.svg"
                        height: styleMusic.common.expandedItem
                        width: styleMusic.common.expandedItem
                        y: parent.y + (styleMusic.artists.itemHeight / 2) - (height / 2)
                    }

                    MouseArea {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.top: parent.top
                        width: styleMusic.common.expandedItem * 3
                        onClicked: {
                           if(expandable.visible) {
                               customdebug("clicked collapse")
                               expandable.visible = false
                               track.height = styleMusic.artists.itemHeight

                           }
                           else {
                               customdebug("clicked expand")
                               collapseExpand(-1);  // collapse all others
                               expandable.visible = true
                               track.height = styleMusic.artists.expandedHeight
                           }
                       }
                   }

                    Rectangle {
                        id: expandable
                        color: "transparent"
                        height: styleMusic.artists.expandHeight
                        visible: false
                        MouseArea {
                           anchors.fill: parent
                           onClicked: {
                               customdebug("User pressed outside the playlist item and expanded items.")
                           }
                        }

                        Component.onCompleted: {
                            collapseExpand.connect(onCollapseExpand);
                        }

                        function onCollapseExpand(indexCol)
                        {
                            if ((indexCol === index || indexCol === -1) && expandable !== undefined && expandable.visible === true)
                            {
                                customdebug("auto collapse")
                                expandable.visible = false
                                track.height = styleMusic.artists.itemHeight
                            }
                        }

                        // background for expander
                        Rectangle {
                            id: expandedBackground
                            anchors.top: parent.top
                            anchors.topMargin: styleMusic.artists.itemHeight
                            color: styleMusic.common.black
                            height: styleMusic.artists.expandedHeight - styleMusic.artists.itemHeight
                            width: track.width
                            opacity: 0.4
                        }

                        // add to playlist
                        Rectangle {
                            id: playlistRow
                            anchors.top: expandedBackground.top
                            anchors.left: parent.left
                            anchors.leftMargin: styleMusic.artists.expandedLeftMargin
                            color: "transparent"
                            height: expandedBackground.height
                            width: units.gu(15)
                            Icon {
                                id: playlistTrack
                                anchors.top: parent.top
                                anchors.topMargin: height/2
                                color: styleMusic.common.white
                                name: "add"
                                height: styleMusic.common.expandedItem
                                width: styleMusic.common.expandedItem
                            }
                            Label {
                                anchors.left: playlistTrack.right
                                anchors.leftMargin: units.gu(0.5)
                                anchors.top: parent.top
                                anchors.topMargin: units.gu(0.5)
                                color: styleMusic.common.white
                                fontSize: "small"
                                width: units.gu(5)
                                height: parent.height
                                text: i18n.tr("Add to playlist")
                                wrapMode: Text.WordWrap
                            }
                            MouseArea {
                               anchors.fill: parent
                               onClicked: {
                                   expandable.visible = false
                                   track.height = styleMusic.artists.itemHeight
                                   chosenArtist = artist
                                   chosenTitle = title
                                   chosenTrack = file
                                   chosenAlbum = album
                                   chosenCover = cover
                                   chosenGenre = genre
                                   chosenIndex = index
                                   console.debug("Debug: Add track to playlist")
                                   PopupUtils.open(Qt.resolvedUrl("MusicaddtoPlaylist.qml"), mainView,
                                   {
                                       title: i18n.tr("Select playlist")
                                   } )
                             }
                           }
                        }
                        // Queue
                        Rectangle {
                            id: queueRow
                            anchors.top: expandedBackground.top
                            anchors.left: playlistRow.left
                            anchors.leftMargin: units.gu(15)
                            color: "transparent"
                            height: expandedBackground.height
                            width: units.gu(15)
                            Image {
                                id: queueTrack
                                anchors.top: parent.top
                                anchors.topMargin: height/2
                                source: "images/queue.png"
                                height: styleMusic.common.expandedItem
                                width: styleMusic.common.expandedItem
                            }
                            Label {
                                anchors.left: queueTrack.right
                                anchors.leftMargin: units.gu(0.5)
                                anchors.top: parent.top
                                anchors.topMargin: units.gu(0.5)
                                color: styleMusic.common.white
                                fontSize: "small"
                                width: units.gu(5)
                                height: parent.height
                                text: i18n.tr("Add to queue")
                                wrapMode: Text.WordWrap
                            }
                            MouseArea {
                               anchors.fill: parent
                               onClicked: {
                                   expandable.visible = false
                                   track.height = styleMusic.artists.itemHeight
                                   console.debug("Debug: Add track to queue: " + title)
                                   trackQueue.model.append({"title": title, "artist": artist, "file": file, "album": album, "cover": cover, "genre": genre})
                             }
                           }
                        }
                    }
                    onFocusChanged: {
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
