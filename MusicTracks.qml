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
                        anchors {
                            left: trackCover.right
                            leftMargin: units.gu(1.5)
                            right: parent.right
                            rightMargin: units.gu(1.5)
                            top: parent.top
                            topMargin: units.gu(2)
                        }
                        elide: Text.ElideRight
                        fontSize: "x-small"
                        height: units.gu(1)
                        maximumLineCount: 2
                        text: artist
                        wrapMode: Text.NoWrap
                    }
                    Label {
                        id: trackTitle
                        anchors {
                            left: trackCover.right
                            leftMargin: units.gu(1.5)
                            right: parent.right
                            rightMargin: units.gu(1.5)
                            top: trackArtist.bottom
                            topMargin: units.gu(1.5)
                        }
                        color: styleMusic.common.music
                        elide: Text.ElideRight
                        fontSize: "small"
                        height: units.gu(2)
                        maximumLineCount: 1
                        objectName: "tracktitle"
                        text: track.title
                        wrapMode: Text.NoWrap
                    }
                    Label {
                        id: trackAlbum
                        anchors {
                            left: trackCover.right
                            leftMargin: units.gu(1.5)
                            right: parent.right
                            rightMargin: units.gu(1.5)
                            top: trackTitle.bottom
                            topMargin: units.gu(1.5)
                        }
                        fontSize: "xx-small"
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        text: album
                        wrapMode: Text.NoWrap
                    }
                }

                Expander {
                    id: expandable
                    anchors {
                        fill: parent
                    }
                    addToPlaylist: true
                    addToQueue: true
                    listItem: track
                    model: libraryModel.model.get(index)
                }

                states: State {
                    name: "Current"
                    when: track.ListView.isCurrentItem
                }
            }
        }
    }
}

