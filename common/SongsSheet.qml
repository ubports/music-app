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
import Ubuntu.MediaScanner 0.1
import Ubuntu.Thumbnailer 0.1
import QtQuick.LocalStorage 2.0
import "../meta-database.js" as Library

Item {
    id: sheetItem

    property string line1: ""
    property string line2: ""
    property string songtitle: ""
    property var covers: []
    property string length: ""
    property string file: ""
    property string year: ""
    property bool isAlbum: false
    property alias sheet: sheetComponent

    property alias album: songsModel.album

    SongsModel {
        id: songsModel
        store: musicStore
    }

    Component {
        id: sheetComponent
        DefaultSheet {
            id: sheet
            anchors.bottomMargin: units.gu(.5)
            doneButton: false
            contentsHeight: units.gu(80)

            onVisibleChanged: {
                if (visible) {
                    musicToolbar.setSheet(sheet)
                }
                else {
                    musicToolbar.removeSheet(sheet)
                }
            }

            ListView {
                clip: true
                id: albumtrackslist
                width: parent.width
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                model: songsModel

                delegate: albumTracksDelegate
                header: ListItem.Standard {
                    id: albumInfo
                    width: parent.width
                    height: units.gu(22)

                    CoverRow {
                        id: albumImage
                        anchors {
                            top: parent.top
                            left: parent.left
                            margins: units.gu(1)
                        }
                        count: sheetItem.covers.length
                        size: units.gu(20)
                        covers: sheetItem.covers
                        spacing: units.gu(2)
                    }

                    Label {
                        id: albumArtist
                        objectName: "albumsheet-albumartist"
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                        fontSize: "small"
                        color: styleMusic.common.subtitle
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
                        color: styleMusic.common.subtitle
                        anchors.left: albumImage.right
                        anchors.leftMargin: units.gu(1)
                        anchors.top: albumLabel.bottom
                        anchors.topMargin: units.gu(2)
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1.5)
                        elide: Text.ElideRight
                        text: isAlbum ? i18n.tr(year + " | %1 song", year + " | %1 songs", albumtrackslist.count).arg(albumtrackslist.count)
                                      : i18n.tr("%1 song", "%1 songs", albumtrackslist.count).arg(albumtrackslist.count)

                    }

                    // Play
                    Rectangle {
                        id: playRow
                        anchors.top: albumYear.bottom
                        anchors.topMargin: units.gu(1)
                        anchors.left: albumImage.right
                        anchors.leftMargin: units.gu(1)
                        color: "transparent"
                        height: units.gu(4)
                        width: units.gu(15)
                        Image {
                            id: playTrack
                            objectName: "albumsheet-playtrack"
                            anchors.verticalCenter: parent.verticalCenter
                            source: "../images/add-to-playback.png"
                            height: styleMusic.common.expandedItem
                            width: styleMusic.common.expandedItem
                        }
                        Label {
                            anchors.left: playTrack.right
                            anchors.leftMargin: units.gu(0.5)
                            anchors.verticalCenter: parent.verticalCenter
                            fontSize: "small"
                            color: styleMusic.common.subtitle
                            width: parent.width - playTrack.width - units.gu(1)
                            text: i18n.tr("Play all")
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                trackClickedMediaScanner2(albumtrackslist.model, 0)  // play track

                                if (isAlbum) {
                                    Library.addRecent(sheetItem.line2, sheetItem.line1, sheetItem.covers[0], sheetItem.line2, "album")
                                    mainView.hasRecent = true
                                    recentModel.filterRecent()
                                } else if (sheetItem.line1 == "Playlist") {
                                    Library.addRecent(sheetItem.line2, "Playlist", sheetItem.covers[0], sheetItem.line2, "playlist")
                                    mainView.hasRecent = true
                                    recentModel.filterRecent()
                                }

                                // TODO: This closes the SDK defined sheet
                                //       component. It should be able to close
                                //       albumSheet.
                                PopupUtils.close(sheet)
                            }
                        }
                    }

                    // Queue
                    Rectangle {
                        id: queueAllRow
                        anchors.top: playRow.bottom
                        anchors.topMargin: units.gu(1)
                        anchors.left: albumImage.right
                        anchors.leftMargin: units.gu(1)
                        color: "transparent"
                        height: units.gu(4)
                        width: units.gu(15)
                        Image {
                            id: queueAll
                            objectName: "albumsheet-queue-all"
                            anchors.verticalCenter: parent.verticalCenter
                            source: "../images/add.svg"
                            height: styleMusic.common.expandedItem
                            width: styleMusic.common.expandedItem
                        }
                        Label {
                            anchors.left: queueAll.right
                            anchors.leftMargin: units.gu(0.5)
                            anchors.verticalCenter: parent.verticalCenter
                            fontSize: "small"
                            color: styleMusic.common.subtitle
                            width: parent.width - queueAll.width - units.gu(1)
                            text: i18n.tr("Add to queue")
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                addQueueFromModelMediaScanner2(albumtrackslist.model)
                            }
                        }
                    }
                }

                Component {
                    id: albumTracksDelegate

                    ListItem.Standard {
                        id: track
                        objectName: "albumsheet-track"
                        iconFrame: false
                        progression: false
                        height: isAlbum ? styleMusic.albums.itemHeight : styleMusic.common.albumSize + units.gu(2)

                        MouseArea {
                            anchors.fill: parent
                            onDoubleClicked: {
                            }
                            onClicked: {
                                if (focus == false) {
                                    focus = true
                                }
                                trackClickedMediaScanner2(albumtrackslist.model, index)  // play track
                                if (isAlbum) {
                                    Library.addRecent(sheetItem.line2, sheetItem.line1, sheetItem.covers[0], sheetItem.line2, "album")
                                    mainView.hasRecent = true
                                    recentModel.filterRecent()
                                } else if (sheetItem.line1 == "Playlist") {
                                    Library.addRecent(sheetItem.line2, "Playlist", sheetItem.covers[0], sheetItem.line2, "playlist")
                                    mainView.hasRecent = true
                                    recentModel.filterRecent()
                                }

                                // TODO: This closes the SDK defined sheet
                                //       component. It should be able to close
                                //       albumSheet.
                                PopupUtils.close(sheet)
                            }
                        }

                        UbuntuShape {
                            id: trackCover
                            anchors {
                                left: parent.left
                                leftMargin: units.gu(2)
                                top: parent.top
                                topMargin: units.gu(1)
                            }
                            width: styleMusic.common.albumSize
                            height: styleMusic.common.albumSize
                            visible: !isAlbum
                            image: Image {
                                source: model.art
                                onStatusChanged: {
                                    if (status === Image.Error) {
                                        source = Qt.resolvedUrl("../images/music-app-cover@30.png")
                                    }
                                }
                            }
                        }

                        Label {
                            id: trackArtist
                            wrapMode: Text.NoWrap
                            maximumLineCount: 2
                            fontSize: "x-small"
                            color: styleMusic.common.subtitle
                            visible: !isAlbum
                            anchors {
                                left: trackCover.right
                                leftMargin: units.gu(2)
                                top: parent.top
                                topMargin: units.gu(1.5)
                                right: expandItem.left
                                rightMargin: units.gu(1.5)
                            }
                            elide: Text.ElideRight
                            text: model.author
                        }

                        Label {
                            id: trackTitle
                            objectName: "albumsheet-tracktitle"
                            wrapMode: Text.NoWrap
                            maximumLineCount: 1
                            fontSize: "medium"
                            color: styleMusic.common.subtitle
                            anchors {
                                left: isAlbum ? parent.left : trackCover.right
                                leftMargin: units.gu(2)
                                top: isAlbum ? parent.top : trackArtist.bottom
                                topMargin: units.gu(1)
                                right: expandItem.left
                                rightMargin: units.gu(1.5)
                            }
                            elide: Text.ElideRight
                            text: model.title
                        }

                        Label {
                            id: trackAlbum
                            wrapMode: Text.NoWrap
                            maximumLineCount: 2
                            fontSize: "xx-small"
                            color: styleMusic.common.subtitle
                            visible: !isAlbum
                            anchors {
                                left: trackCover.right
                                leftMargin: units.gu(2)
                                top: trackTitle.bottom
                                topMargin: units.gu(2)
                                right: expandItem.left
                                rightMargin: units.gu(1.5)
                            }
                            elide: Text.ElideRight
                            text: model.album
                        }

                        Image {
                            id: expandItem
                            objectName: "albumsheet-expanditem"
                            anchors.right: parent.right
                            anchors.rightMargin: units.gu(2)
                            source: expandable.visible ? "../images/dropdown-menu-up.svg" : "../images/dropdown-menu.svg"
                            height: styleMusic.common.expandedItem
                            width: styleMusic.common.expandedItem
                            y: parent.y + ((isAlbum ? styleMusic.albums.itemHeight : styleMusic.common.albumSize + units.gu(2)) / 2) - (height / 2)
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
                                    track.height = isAlbum ? styleMusic.albums.itemHeight : styleMusic.common.albumSize + units.gu(2)
                                }
                                else {
                                    customdebug("clicked expand")
                                    collapseExpand(-1);  // collapse all others
                                    expandable.visible = true
                                    track.height = isAlbum ? styleMusic.albums.expandedHeight : styleMusic.common.expandedHeight
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
                                    track.height = isAlbum ? styleMusic.albums.itemHeight : styleMusic.common.albumSize + units.gu(2)
                                }
                            }

                            // background for expander
                            Rectangle {
                                id: expandedBackground
                                anchors.top: parent.top
                                anchors.topMargin: isAlbum ? styleMusic.albums.itemHeight : styleMusic.common.albumSize + units.gu(2)
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
                                        track.height = isAlbum ? styleMusic.albums.itemHeight : styleMusic.common.albumSize + units.gu(2)
                                        chosenElement = model
                                        console.debug("Debug: Add track to playlist")
                                        PopupUtils.open(Qt.resolvedUrl("../MusicaddtoPlaylist.qml"), mainView,
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
                                        track.height = isAlbum ? styleMusic.albums.itemHeight : styleMusic.common.albumSize + units.gu(2)
                                        console.debug("Debug: Add track to queue: " + title)
                                        trackQueue.append(model)
                                    }
                                }
                            }
                        }

                        onFocusChanged: {
                        }
                        Component.onCompleted: {
                            if (index === 0)
                            {
                                sheetItem.file = model.filename;
                                sheetItem.year = model.date;
                            }
                        }
                    }
                }
            }
        }
    }
}

