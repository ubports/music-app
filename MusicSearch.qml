/*
 * Copyright (C) 2014 Andrew Hayzen <ahayzen@gmail.com>
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

import QtMultimedia 5.0
import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Components.Popups 0.1
import QtQuick.LocalStorage 2.0
import "playlists.js" as Playlists
import "meta-database.js" as Library
import "common"

Item {
    id: sheetItem

    property alias sheet: sheetComponent
    property bool sheetVisible: false

    Component {
        id: sheetComponent

        // Sheet to search for music tracks
         DefaultSheet {
             id: searchTrack
             title: i18n.tr("Search")
             contentsHeight: units.gu(80)

             onDoneClicked: PopupUtils.close(searchTrack)

             Component.onCompleted: {
                 searchField.forceActiveFocus()
             }

             onVisibleChanged: {
                 if (visible) {
                     musicToolbar.setSheet(searchTrack)
                     sheetVisible = true
                 }
                 else {
                     musicToolbar.removeSheet(searchTrack)
                     sheetVisible = false
                 }
             }

             TextField {
                 id: searchField
                 anchors {
                     left: parent.left;
                     leftMargin: units.gu(2);
                     top: parent.top;
                     right: parent.right;
                     rightMargin: units.gu(2);
                 }

                 width: parent.width/1.5
                 placeholderText: "Search"
                 hasClearButton: true
                 highlighted: true
                 focus: true
                 inputMethodHints: Qt.ImhNoPredictiveText
                 //canPaste: true // why work, you do not, hrm?

                 // search icon
                 primaryItem: Image {
                     height: parent.height*0.5
                     width: parent.height*0.5
                     anchors.verticalCenter: parent.verticalCenter
                     anchors.verticalCenterOffset: -units.gu(0.2)
                     source: Qt.resolvedUrl("images/search.svg")
                 }

                 onTextChanged: {
                     searchTimer.start() // start the countdown, baby!
                 }

                 // Provide a small pause before search
                 Timer {
                     id: searchTimer
                     interval: 1500
                     repeat: false
                     onTriggered: {
                         if(searchField.text) {
                             searchModel.filterSearch(searchField.text) // query the databse
                             searchActivity.running = true // start the activity indicator
                         }
                         else {
                             customdebug("No search terms.")
                             searchModel.filterSearch("empty somehow?")
                         }
                        indicatorTimer.start()
                     }
                 }
                 // and onother one for the indicator
                 Timer {
                     id: indicatorTimer
                     interval: 500
                     repeat: false
                     onTriggered: {
                         searchActivity.running = false
                     }
                 }

                 // Indicator to show search activity
                 ActivityIndicator {
                     id: searchActivity
                     anchors {
                         verticalCenter: searchField.verticalCenter;
                         right: searchField.right;
                         rightMargin: units.gu(1)
                     }
                     running: false
                 }
             }

             Rectangle {
                 width: parent.width
                 height: parent.height
                 color: "transparent"
                 clip: true
                 anchors {
                     top: searchField.bottom
                     bottom: parent.bottom
                     left: parent.left
                     right: parent.right
                 }

                 // show each playlist and make them chosable
                 ListView {
                     id: searchTrackView
                     objectName: "searchtrackview"
                     width: parent.width
                     height: parent.width
                     model: searchModel.model

                     onMovementStarted: {
                         searchTrackView.forceActiveFocus()
                     }

                     delegate: ListItem.Standard {
                            id: search
                            objectName: "playlist"
                            width: parent.width
                            height: styleMusic.common.itemHeight
                            property string title: model.title
                            property string artist: model.artist
                            property string file: model.file
                            property string album: model.album
                            property string cover: model.cover
                            property string genre: model.genre

                            onClicked: {
                                console.debug("Debug: "+title+" added to queue")
                                // now play this track, but keep current queue
                                trackQueue.append(model)
                                trackClicked(trackQueue, trackQueue.model.count - 1, true)
                                onDoneClicked: PopupUtils.close(searchTrack)
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
                                text: artist
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
                                text: title
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
                                    expandItem.forceActiveFocus()
                                    if(expandable.visible) {
                                        customdebug("clicked collapse")
                                        expandable.visible = false
                                        search.height = styleMusic.common.itemHeight
                                        Rotation: {
                                            source: expandItem;
                                            angle: 0;
                                        }
                                    }
                                    else {
                                        customdebug("clicked expand")
                                        collapseExpand(-1);  // collapse all others
                                        expandable.visible = true
                                        search.height = styleMusic.common.expandedHeight
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
                                        search.height = styleMusic.common.itemHeight
                                    }
                                }

                                // background for expander
                                Rectangle {
                                    id: expandedBackground
                                    anchors.top: parent.top
                                    anchors.topMargin: styleMusic.common.itemHeight
                                    color: styleMusic.common.black
                                    height: styleMusic.common.expandedHeight - styleMusic.common.itemHeight
                                    width: search.width
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
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: styleMusic.common.white
                                        name: "add"
                                        height: styleMusic.common.expandedItem
                                        width: styleMusic.common.expandedItem
                                    }
                                    Label {
                                        objectName: "songstab_addtoplaylist"
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
                                            search.height = styleMusic.common.itemHeight
                                            chosenElement = model
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
                                        anchors.verticalCenter: parent.verticalCenter
                                        source: "images/queue.png"
                                        height: styleMusic.common.expandedItem
                                        width: styleMusic.common.expandedItem
                                    }
                                    Label {
                                        objectName: "songstab_addtoqueue"
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
                                            search.height = styleMusic.common.itemHeight
                                            console.debug("Debug: Add track to queue: " + title)
                                            trackQueue.append(model)
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
                                            search.height = styleMusic.common.itemHeight
                                            customdebug("Share")
                                        }
                                    }
                                }
                            }
                     }
                 }

             }
         }
    }
}
