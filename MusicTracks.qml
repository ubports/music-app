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
import "common"


Page {
    id: mainpage
    title: i18n.tr("Songs")

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

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (focus == false) {
                            focus = true
                        }

                        trackClicked(libraryModel, index)  // play track
                    }
                }

                Rectangle {
                    id: trackContainer;
                    anchors {
                        fill: parent
                        rightMargin: expandable.expanderButtonWidth
                    }
                    color: "transparent"
                    UbuntuShape {
                        id: trackCover
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(2)
                        anchors.top: parent.top
                        anchors.topMargin: units.gu(1)
                        width: styleMusic.common.albumSize
                        height: styleMusic.common.albumSize
                        image: Image {
                            source: cover !== "" ? cover : Qt.resolvedUrl("images/music-app-cover@30.png")
                            onStatusChanged: {
                                if (status === Image.Error) {
                                    source = Qt.resolvedUrl("images/music-app-cover@30.png")
                                }
                            }
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
                        anchors.right: parent.right
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
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1.5)
                        elide: Text.ElideRight
                        text: track.title
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
                        anchors.right: parent.right
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
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1.5)
                        elide: Text.ElideRight
                        visible: false
                        text: ""
                    }
                }

                Expandable {
                    id: expandable
                    anchors {
                        fill: parent
                    }
                    addToPlaylist: true
                    addToQueue: true
                    listItem: track
                    model: track.model
                }

                states: State {
                    name: "Current"
                    when: track.ListView.isCurrentItem
                }
            }
        }
    }
}

