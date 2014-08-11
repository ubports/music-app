/*
 * Copyright (C) 2013, 2014
 *      Andrew Hayzen <ahayzen@gmail.com>
 *      Daniel Holm <d.holmen@gmail.com>
 *      Victor Thompson <victor.thompson@gmail.com>
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
import Ubuntu.MediaScanner 0.1
import Ubuntu.Thumbnailer 0.1
import QtQuick.LocalStorage 2.0
import "playlists.js" as Playlists
import "common"
import "common/ListItemActions"

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
                     interval: 500
                     repeat: false
                     onTriggered: {
                         songsSearchModel.query = searchField.text;
                         searchActivity.running = true // start the activity indicator

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
                 visible: searchField.text
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
                     model: SongsSearchModel {
                        id: songsSearchModel
                        store: musicStore
                     }

                     onMovementStarted: {
                         searchTrackView.forceActiveFocus()
                     }

                     delegate: ListItemWithActions {
                            id: search
                            color: "transparent"
                            objectName: "playlist"
                            width: parent.width
                            height: styleMusic.common.itemHeight

                            rightSideActions: [
                                AddToQueue {

                                },
                                AddToPlaylist {

                                }
                            ]

                            onItemClicked: {
                                console.debug("Debug: "+title+" added to queue")
                                // now play this track, but keep current queue
                                trackQueue.append(model)
                                trackQueueClick(trackQueue.model.count - 1);
                                onDoneClicked: PopupUtils.close(searchTrack)
                            }

                            MusicRow {
                                covers: [{author: model.author, album: model.title}]
                                column: Column {
                                    spacing: units.gu(1)
                                    Label {
                                        id: trackArtist
                                        color: styleMusic.common.subtitle
                                        fontSize: "x-small"
                                        text: model.author
                                    }
                                    Label {
                                        id: trackTitle
                                        color: styleMusic.common.music
                                        fontSize: "small"
                                        objectName: "tracktitle"
                                        text: model.title
                                    }
                                    Label {
                                        id: trackAlbum
                                        color: styleMusic.common.subtitle
                                        fontSize: "xx-small"
                                        text: model.album
                                    }
                                }
                            }
                     }
                 }
             }
         }
    }
}
