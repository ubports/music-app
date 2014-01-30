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

// Sheet to search for music tracks
 DefaultSheet {
     id: searchTrack
     title: i18n.tr("Search")
     contentsHeight: units.gu(80)

     onDoneClicked: PopupUtils.close(searchTrack)

     Component.onCompleted: {
     }

     onVisibleChanged: {
         if (visible === true)
         {
             musicToolbar.disableToolbar()
         }
         else
         {
             musicToolbar.enableToolbar()
         }
     }

     TextField {
         id: searchField
         anchors {
             left: parent.left;
             leftMargin: units.gu(2);
             top: parent.top;
             //bottom: parent.bottom;
             right: parent.right;
             rightMargin: units.gu(2);
         }

         width: parent.width/1.5
         placeholderText: "Search"
         hasClearButton: true

         // Provide a small pause before going online to search
         Timer {
             id: searchTimer
             interval: 2000
             repeat: false
         }

         onTextChanged: {
            searchActivity.running = true // start the activity indicator
            Library.search(searchField.text) // query the databse
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
             delegate: ListItem.Standard {
                    id: search
                    objectName: "playlist"
                    height: units.gu(8)
                    property string name: model.name
                    property string artist: model.artist
                    onClicked: {
                        console.debug("Debug: "+chosenTrack+" added to "+name)
                        // now play this track, but keep current queue
                        // add to queue
                        // play track from queue
                        onDoneClicked: PopupUtils.close(searchTrack)
                    }

                    Label {
                        id: trackName
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            leftMargin: units.gu(11)
                            topMargin: units.gu(2)
                            bottomMargin: units.gu(4)
                        }
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                        fontSize: "medium"
                        elide: Text.ElideRight
                        text: track.artist + " - " + track.name
                    }
             }
         }

     }
 }
