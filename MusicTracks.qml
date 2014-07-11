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

                MusicRow {
                    covers: [{author: model.author, album: model.album}]
                    column: Column {
                        spacing: units.gu(1)
                        Label {
                            id: trackArtist
                            color: styleMusic.common.subtitle
                            elide: Text.ElideRight
                            fontSize: "x-small"
                            maximumLineCount: 2
                            text: model.author
                            wrapMode: Text.NoWrap
                        }

                        Label {
                            id: trackTitle
                            color: styleMusic.common.music
                            elide: Text.ElideRight
                            fontSize: "medium"
                            maximumLineCount: 1
                            objectName: "tracktitle"
                            text: model.title
                            wrapMode: Text.NoWrap
                        }

                        Label {
                            id: trackAlbum
                            color: styleMusic.common.subtitle
                            elide: Text.ElideRight
                            fontSize: "xx-small"
                            maximumLineCount: 2
                            text: model.album
                            wrapMode: Text.NoWrap
                        }
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

