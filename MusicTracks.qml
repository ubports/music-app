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


Page {
    id: mainpage
    title: i18n.tr("Music")

    MusicSettings {
        id: musicSettings
    }

    onVisibleChanged: {
        if (visible === true)
        {
            musicToolbar.setPage(mainpage);
        }
    }

    ListView {
        id: tracklist
        anchors.fill: parent
        anchors.bottomMargin: musicToolbar.mouseAreaOffset + musicToolbar.minimizedHeight
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
                    id: trackArtist
                    wrapMode: Text.NoWrap
                    maximumLineCount: 2
                    fontSize: "x-small"
                    anchors.left: trackCover.left
                    anchors.leftMargin: units.gu(11)
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(1.5)
                    anchors.right: expandItem.left
                    anchors.rightMargin: units.gu(1.5)
                    elide: Text.ElideRight
                    text: artist == "" ? "" : artist
                }
                Label {
                    id: trackTitle
                    objectName: "tracktitle"
                    wrapMode: Text.NoWrap
                    maximumLineCount: 1
                    fontSize: "small"
                    color: styleMusic.common.music
                    anchors.left: trackCover.left
                    anchors.leftMargin: units.gu(11)
                    anchors.top: trackArtist.bottom
                    anchors.topMargin: units.gu(1)
                    anchors.right: expandItem.left
                    anchors.rightMargin: units.gu(1.5)
                    elide: Text.ElideRight
                    text: track.title == "" ? track.file : track.title
                }
                Label {
                    id: trackAlbum
                    wrapMode: Text.NoWrap
                    maximumLineCount: 2
                    fontSize: "xx-small"
                    anchors.left: trackCover.left
                    anchors.leftMargin: units.gu(11)
                    anchors.top: trackTitle.bottom
                    anchors.topMargin: units.gu(2)
                    anchors.right: expandItem.left
                    anchors.rightMargin: units.gu(1.5)
                    elide: Text.ElideRight
                    text: album
                }
                Label {
                    id: trackDuration
                    wrapMode: Text.NoWrap
                    maximumLineCount: 2
                    fontSize: "small"
                    color: styleMusic.common.music
                    anchors.left: trackCover.left
                    anchors.leftMargin: units.gu(12)
                    anchors.top: trackAlbum.bottom
                    anchors.right: expandItem.left
                    anchors.rightMargin: units.gu(1.5)
                    elide: Text.ElideRight
                    visible: false
                    text: ""
                }
                onFocusChanged: {
                }
                MouseArea {
                    anchors.fill: parent
                    onDoubleClicked: {
                    }
                    onClicked: {
                        if (focus == false) {
                            focus = true
                        }

                        trackClicked(libraryModel, index)  // play track
                        // collapse expanded item on click on track
                        if(expandable.visible) {
                            expandable.visible = false
                            track.height = styleMusic.common.itemHeight
                        }
                    }
                }
                states: State {
                    name: "Current"
                    when: track.ListView.isCurrentItem
                }
                //Icon { // use for 1.0
                Image {
                    id: expandItem
                    objectName: "trackimage"
                    anchors.right: parent.right
                    anchors.rightMargin: units.gu(2)
                    //  name: "dropdown-menu" Use for 1.0
                    source: expandable.visible ? "images/dropdown-menu-up.svg" : "images/dropdown-menu.svg"
                    height: styleMusic.common.expandedItem
                    width: styleMusic.common.expandedItem
                    y: parent.y + (styleMusic.common.itemHeight / 2) - (height / 2)
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
                            track.height = styleMusic.common.itemHeight
                            Rotation: {
                                source: expandItem;
                                angle: 0;
                            }
                        }
                        else {
                            customdebug("clicked expand")
                            collapseExpand(-1);  // collapse all others
                            expandable.visible = true
                            track.height = styleMusic.common.expandedHeight
                            Rotation: {
                                source: expandItem;
                                angle: 180;
                            }
                        }
                    }
                }

                Rectangle {
                    id: expandable
                    color: "transparent"
                    height: styleMusic.common.expandHeight
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
                            track.height = styleMusic.common.itemHeight
                        }
                    }

                    // background for expander
                    Rectangle {
                        id: expandedBackground
                        anchors.top: parent.top
                        anchors.topMargin: styleMusic.common.itemHeight
                        color: styleMusic.common.black
                        height: styleMusic.common.expandedHeight - styleMusic.common.itemHeight
                        width: track.width
                        opacity: 0.4
                    }

                    // add to playlist
                    Rectangle {
                        id: playlistRow
                        anchors.top: expandedBackground.top
                        anchors.left: parent.left
                        anchors.leftMargin: styleMusic.common.expandedLeftMargin
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
                                track.height = styleMusic.common.itemHeight
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
                            objectName: "songstab_addtoqueue"
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
                                track.height = styleMusic.common.itemHeight
                                console.debug("Debug: Add track to queue: " + title)
                                trackQueue.model.append({"title": title, "artist": artist, "file": file, "album": album, "cover": cover, "genre": genre})
                            }
                        }
                    }
                    // Share
                    Rectangle {
                        id: shareRow
                        anchors.top: expandedBackground.top
                        anchors.left: queueRow.left
                        anchors.leftMargin: units.gu(15)
                        color: "transparent"
                        height: expandedBackground.height
                        width: units.gu(15)
                        visible: false
                        Icon {
                            id: shareTrack
                            color: styleMusic.common.white
                            name: "share"
                            height: styleMusic.common.expandedItem
                            width: styleMusic.common.expandedItem
                        }
                        Label {
                            anchors.left: shareTrack.right
                            anchors.leftMargin: units.gu(0.5)
                            anchors.top: parent.top
                            anchors.topMargin: units.gu(0.5)
                            color: styleMusic.common.white
                            fontSize: "small"
                            text: i18n.tr("Share")
                            width: units.gu(5)
                            height: parent.height
                            wrapMode: Text.WordWrap
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                expandable.visible = false
                                track.height = styleMusic.common.itemHeight
                                customdebug("Share")
                            }
                        }
                    }
                }
            }
        }
    }
}

