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

import QtQuick 2.3
import Ubuntu.Components 1.1
import Ubuntu.MediaScanner 0.1
import Ubuntu.Thumbnailer 0.1
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import "settings.js" as Settings
import "playlists.js" as Playlists
import "common"
import "common/ListItemActions"


MusicPage {
    id: mainpage
    objectName: "tracksPage"
    title: i18n.tr("Songs")

    ListView {
        id: tracklist
        anchors.fill: parent
        anchors.bottomMargin: musicToolbar.mouseAreaOffset + musicToolbar.minimizedHeight
        highlightFollowsCurrentItem: false
        objectName: "trackstab-listview"
        model: SortFilterModel {
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

            ListItemWithActions {
                id: track
                color: "transparent"
                objectName: "tracksPageListItem" + index
                width: parent.width
                height: styleMusic.common.itemHeight

                rightSideActions: [
                    AddToQueue {
                    },
                    AddToPlaylist {

                    }
                ]
                triggerActionOnMouseRelease: true

                // TODO: If http://pad.lv/1354753 is fixed to expose whether the Shape should appear pressed, update this as well.
                onPressedChanged: musicRow.pressed = pressed

                onItemClicked: trackClicked(tracklist.model, index)  // play track

                MusicRow {
                    id: musicRow
                    covers: [{art: model.art}]
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
                            fontSize: "medium"
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

                states: State {
                    name: "Current"
                    when: track.ListView.isCurrentItem
                }
            }
        }
    }
}

