/*
 * Copyright (C) 2013 Andrew Hayzen <ahayzen@gmail.com>
 *                    Daniel Holm <d.holmen@gmail.com>
 *                    Victor Thompson <victor.thompson@gmail.com>
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
import QtQuick.LocalStorage 2.0
import "../meta-database.js" as Library

Item {
    id: sheetItem

    property string line1: ""
    property string line2: ""
    property string songtitle: ""
    property string cover: ""
    property string length: ""
    property string file: ""
    property string year: ""
    property bool isAlbum: false
    property alias sheet: sheetComponent

    Component {
        id: sheetComponent
        DefaultSheet {
            id: sheet
            anchors.bottomMargin: units.gu(.5)
            doneButton: false
            contentsHeight: parent.height
            contentsWidth: parent.width

            ListView {
                clip: true
                id: albumtrackslist
                width: parent.width
                anchors.top: parent.top
                anchors.bottom: parent.bottom
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
                            source: cover
                        }
                    }
                    Label {
                        id: albumArtist
                        objectName: "albumsheet-albumartist"
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                        fontSize: "small"
                        anchors.left: albumImage.right
                        anchors.leftMargin: units.gu(1)
                        anchors.top: parent.top
                        anchors.topMargin: units.gu(1.5)
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1.5)
                        elide: Text.ElideRight
                        text: line1
                    }
                    Label {
                        id: albumLabel
                        wrapMode: Text.NoWrap
                        maximumLineCount: 2
                        fontSize: "medium"
                        color: styleMusic.common.music
                        anchors.left: albumImage.right
                        anchors.leftMargin: units.gu(1)
                        anchors.top: albumArtist.bottom
                        anchors.topMargin: units.gu(0.8)
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1.5)
                        elide: Text.ElideRight
                        text: line2
                    }
                    Label {
                        id: albumYear
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                        fontSize: "x-small"
                        anchors.left: albumImage.right
                        anchors.leftMargin: units.gu(1)
                        anchors.top: albumLabel.bottom
                        anchors.topMargin: units.gu(2)
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1.5)
                        elide: Text.ElideRight
                        text: isAlbum ? i18n.tr(year + " | %1 song", year + " | %1 songs", albumTracksModel.model.count).arg(albumTracksModel.model.count)
                                      : i18n.tr("%1 song", "%1 songs", albumTracksModel.model.count).arg(albumTracksModel.model.count)

                    }
                }

                onCountChanged: {
                    albumtrackslist.currentIndex = albumTracksModel.indexOf(currentFile)
                }

                Component {
                    id: albumTracksDelegate

                    ListItem.Standard {
                        id: track
                        objectName: "albumsheet-track"
                        iconFrame: false
                        progression: false
                        height: styleMusic.albums.itemHeight

                        MouseArea {
                            anchors.fill: parent
                            onDoubleClicked: {
                            }
                            onClicked: {
                                if (focus == false) {
                                    focus = true
                                }
                                trackClicked(albumTracksModel, index)  // play track
                                if (isAlbum) {
                                    Library.addRecent(sheetItem.line2, sheetItem.line1, sheetItem.cover, sheetItem.line2, "album")
                                    mainView.hasRecent = true
                                    recentModel.filterRecent()
                                } else if (sheetItem.line1 == "Playlist") {
                                    Library.addRecent(sheetItem.line2, "Playlist", sheetItem.cover, sheetItem.line2, "playlist")
                                    mainView.hasRecent = true
                                    recentModel.filterRecent()
                                }

                                // TODO: This closes the SDK defined sheet
                                //       component. It should be able to close
                                //       albumSheet.
                                PopupUtils.close(sheet)
                            }
                        }

                        Label {
                            id: trackTitle
                            objectName: "albumsheet-tracktitle"
                            wrapMode: Text.NoWrap
                            height: parent.height
                            width: parent.width
                            maximumLineCount: 1
                            fontSize: "medium"
                            anchors.left: parent.left
                            anchors.leftMargin: units.gu(2)
                            anchors.top: parent.top
                            anchors.topMargin: units.gu(1)
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: units.gu(1)
                            anchors.right: expandItem.left
                            anchors.rightMargin: units.gu(1.5)
                            elide: Text.ElideRight
                            text: model.title
                        }

                        Image {
                            id: expandItem
                            objectName: "albumsheet-expanditem"
                            anchors.right: parent.right
                            anchors.rightMargin: units.gu(2)
                            source: expandable.visible ? "../images/dropdown-menu-up.svg" : "../images/dropdown-menu.svg"
                            height: styleMusic.common.expandedItem
                            width: styleMusic.common.expandedItem
                            y: parent.y + (styleMusic.albums.itemHeight / 2) - (height / 2)
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
                                    track.height = styleMusic.albums.itemHeight
                                }
                                else {
                                    customdebug("clicked expand")
                                    collapseExpand(-1);  // collapse all others
                                    expandable.visible = true
                                    track.height = styleMusic.albums.expandedHeight
                                }
                            }
                        }

                        Rectangle {
                            id: expandable
                            color: "transparent"
                            height: styleMusic.albums.expandHeight
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
                                    track.height = styleMusic.albums.itemHeight
                                }
                            }

                            // background for expander
                            Rectangle {
                                id: expandedBackground
                                anchors.top: parent.top
                                anchors.topMargin: styleMusic.albums.itemHeight
                                color: styleMusic.common.black
                                height: styleMusic.albums.expandedHeight - styleMusic.albums.itemHeight
                                width: track.width
                                opacity: 0.4
                            }

                            // add to playlist
                            Rectangle {
                                id: playlistRow
                                anchors.top: expandedBackground.top
                                anchors.left: parent.left
                                anchors.leftMargin: styleMusic.albums.expandedLeftMargin
                                color: "transparent"
                                height: expandedBackground.height
                                width: units.gu(15)
                                Icon {
                                    id: playlistTrack
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: styleMusic.common.white
                                    name: "add"
                                    height: styleMusic.common.expandedItem
                                    width: styleMusic.common.expandedItem
                                }
                                Label {
                                    anchors.left: playlistTrack.right
                                    anchors.leftMargin: units.gu(0.5)
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: styleMusic.common.white
                                    fontSize: "small"
                                    width: parent.width - playlistTrack.width - units.gu(1)
                                    text: i18n.tr("Add to playlist")
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 3
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        expandable.visible = false
                                        track.height = styleMusic.albums.itemHeight
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
                                    objectName: "albumsheet-queuetrack"
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: "../images/queue.png"
                                    height: styleMusic.common.expandedItem
                                    width: styleMusic.common.expandedItem
                                }
                                Label {
                                    anchors.left: queueTrack.right
                                    anchors.leftMargin: units.gu(0.5)
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: styleMusic.common.white
                                    fontSize: "small"
                                    width: parent.width - queueTrack.width - units.gu(1)
                                    text: i18n.tr("Add to queue")
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 3
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        expandable.visible = false
                                        track.height = styleMusic.albums.itemHeight
                                        console.debug("Debug: Add track to queue: " + title)
                                        trackQueue.model.append({"title": title, "artist": artist, "file": file, "album": album, "cover": cover, "genre": genre})
                                    }
                                }
                            }
                        }

                        onFocusChanged: {
                        }
                        Component.onCompleted: {
                            if (index === 0)
                            {
                                sheetItem.file = model.file;
                                sheetItem.year = model.year;
                            }
                        }
                    }
                }
            }
        }
    }
}

