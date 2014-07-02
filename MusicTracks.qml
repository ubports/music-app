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

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components 1.1 as Toolkit
import Ubuntu.Components.ListItems 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.MediaScanner 0.1
import Ubuntu.Thumbnailer 0.1
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import "settings.js" as Settings
import "playlists.js" as Playlists
import "common"
import "common/ExpanderItems"


MusicPage {
    id: mainpage
    title: i18n.tr("Songs")

    ListView {
        id: tracklist
        anchors.fill: parent
        anchors.bottomMargin: musicToolbar.mouseAreaOffset + musicToolbar.minimizedHeight
        highlightFollowsCurrentItem: false
        model: Toolkit.SortFilterModel {
            id: songsModelFilter
            property alias rowCount: songsModel.rowCount
            model: SongsModel {
                id: songsModel
                store: musicStore
            }
            sort.property: "title"
            sort.order: Qt.AscendingOrder
        }
        delegate: trackDelegate
        Component {
            id: trackDelegate
            ListItem.Standard {
                id: track
                width: parent.width
                height: styleMusic.common.itemHeight

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (focus == false) {
                            focus = true
                        }

                        trackClicked(tracklist.model, index)  // play track
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
                            source: "image://albumart/artist=" + model.author + "&album=" + model.album
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
                        color: styleMusic.common.subtitle
                        anchors.left: trackCover.left
                        anchors.leftMargin: units.gu(11)
                        anchors.top: parent.top
                        anchors.topMargin: units.gu(1.5)
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1.5)
                        elide: Text.ElideRight
                        text: model.author
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
                        text: model.title
                    }
                    Label {
                        id: trackAlbum
                        wrapMode: Text.NoWrap
                        maximumLineCount: 2
                        fontSize: "xx-small"
                        color: styleMusic.common.subtitle
                        anchors.left: trackCover.left
                        anchors.leftMargin: units.gu(11)
                        anchors.top: trackTitle.bottom
                        anchors.topMargin: units.gu(2)
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1.5)
                        elide: Text.ElideRight
                        text: model.album
                    }
                    Label {
                        id: trackDuration
                        wrapMode: Text.NoWrap
                        maximumLineCount: 2
                        fontSize: "small"
                        color: styleMusic.common.subtitle
                        anchors.left: trackCover.left
                        anchors.leftMargin: units.gu(12)
                        anchors.top: trackAlbum.bottom
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1.5)
                        elide: Text.ElideRight
                        visible: false
                        text: ""  // model.duration
                    }
                }

                Expander {
                    id: expandable
                    anchors {
                        fill: parent
                    }
                    listItem: track
                    model: songsModelFilter.get(index, songsModelFilter.RoleModelData)
                    row: Row {
                        AddToPlaylist {

                        }
                        AddToQueue {

                        }
                    }
                }

                states: State {
                    name: "Current"
                    when: track.ListView.isCurrentItem
                }
            }
        }
    }
}

