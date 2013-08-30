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
import org.nemomobile.folderlistmodel 1.0
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import "settings.js" as Settings
import "meta-database.js" as Library
import "playlists.js" as Playlists


Page {
    id: mainpage

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

    title: i18n.tr("Music")

    ListItem.Standard {
        id: recentlyPlayed
        text: "Recently Played"
    }

    ListView {
        id: recentlist
        width: parent.width
        anchors.top: recentlyPlayed.bottom
        //anchors.bottom: genres.top
        spacing: units.gu(2)
        height: units.gu(13)
        // TODO: Update when view counts are collected
        model: albumModel.model
        delegate: recentDelegate
        orientation: ListView.Horizontal

        Component {
            id: recentDelegate
            Item {
                id: recentItem
                height: units.gu(13)
                width: units.gu(13)
                UbuntuShape {
                    id: recentShape
                    height: recentItem.width
                    width: recentItem.width
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
// TODO: Add the track/album/etc to the queue.
//                MouseArea {
//                    anchors.fill: parent
//                    onDoubleClicked: {
//                    }
//                    onPressAndHold: {
//                    }
//                    onClicked: {
//                        // TODO: Fix model population
//                        albumTracksModel.filterAlbumTracks(album)
//                        albumtrackslist.artist = artist
//                        albumtrackslist.album = album
//                        albumtrackslist.file = file
//                        albumtrackslist.year = year
//                        pageStack.push(albumpage)
//                    }
//                }
            }
        }
    }

    ListItem.Standard {
        id: genres
        anchors.top: recentlist.bottom
        text: "Genres"
    }

    // TODO: add music genres. frequency of play? most tracks?
    Label {
        id: stuff
        fontSize: "large"
        anchors.top: genres.bottom
        anchors.topMargin: units.gu(1)
        anchors.verticalCenter: parent.verticalCenter
        text: "Only the best for me, thanks"
    }

}
