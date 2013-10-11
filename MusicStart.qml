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
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import "settings.js" as Settings
import "meta-database.js" as Library
import "playlists.js" as Playlists

Page {
    id: mainpage
    title: i18n.tr("Music")

    onVisibleChanged: {
        if (visible === true)
        {
            musicToolbar.setPage(mainpage);
        }
    }

    ListItem.Standard {
        id: recentlyPlayed
        text: i18n.tr("Recently Played")
    }

    ListView {
        id: recentlist
        width: parent.width
        anchors.top: recentlyPlayed.bottom
        anchors.topMargin: units.gu(1)
        //anchors.bottom: genres.top
        spacing: units.gu(2)
        height: units.gu(19)
        // TODO: Update when view counts are collected
        model: albumModel.model
        delegate: recentDelegate
        header: Item {
            id: spacer
            width: units.gu(1)
        }
        orientation: ListView.Horizontal

        Component {
            id: recentDelegate
            Item {
                id: recentItem
                height: units.gu(17)
                width: units.gu(17)
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
                        source: cover !== "" ? cover : "images/cover_default.png"
                    }
                }
                UbuntuShape {  // Background so can see text in current state
                    id: albumBg
                    anchors.bottom: parent.bottom
                    color: styleMusic.common.black
                    height: units.gu(6)
                    opacity: .75
                    width: parent.width
                }
                Label {
                    id: albumArtist
                    anchors.top: albumBg.top
                    anchors.topMargin: units.gu(1)
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(1)
                    color: styleMusic.nowPlaying.labelSecondaryColor
                    text: artist
                    fontSize: "x-small"
                    width: parent.width
                }
                Label {
                    id: albumLabel
                    anchors.top: albumArtist.bottom
                    anchors.topMargin: units.gu(0.5)
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(1)
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: units.gu(2)
                    color: styleMusic.nowPlaying.labelSecondaryColor
                    text: album
                    fontSize: "small"
                    width: parent.width
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        recentAlbumTracksModel.filterAlbumTracks(album)
                        trackQueue.model.clear()
                        addQueueFromModel(recentAlbumTracksModel)
                        currentModel = recentAlbumTracksModel
                        currentQuery = recentAlbumTracksModel.query
                        currentParam = recentAlbumTracksModel.param
                        var file = trackQueue.model.get(0).file
                        currentIndex = trackQueue.indexOf(file)
                        queueChanged = true
                        player.stop()
                        player.source = Qt.resolvedUrl(file)
                        player.play()
                        nowPlaying.visible = true
                    }
                }
            }
        }
    }

    ListItem.ThinDivider {
        id: divider
        anchors.top: recentlist.bottom
    }
    ListItem.Standard {
        id: genres
        anchors.top: divider.bottom
        text: i18n.tr("Genres")
    }
    // TODO: add music genres. frequency of play? most tracks?
    ListView {
        id: genrelist
        width: parent.width
        anchors.top: genres.bottom
        anchors.topMargin: units.gu(1)
        spacing: units.gu(2)
        height: units.gu(19)
        model: genreModel.model
        delegate: genreDelegate
        header: Item {
            id: spacer
            width: units.gu(1)
        }
        orientation: ListView.Horizontal

        Component {
            id: genreDelegate
            Item {
                id: genreItem
                height: units.gu(17)
                width: units.gu(17)
                UbuntuShape {
                    id: genreShape
                    height: genreItem.width
                    width: genreItem.width
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
                        property string genre: model.genre
                        source: cover !== "" ? cover : "images/cover_default.png"
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        genreTracksModel.filterGenreTracks(genre)
                        trackQueue.model.clear()
                        addQueueFromModel(genreTracksModel)
                        currentModel = genreTracksModel
                        currentQuery = genreTracksModel.query
                        currentParam = genreTracksModel.param
                        var file = trackQueue.model.get(0).file
                        currentIndex = trackQueue.indexOf(file)
                        queueChanged = true
                        player.stop()
                        player.source = Qt.resolvedUrl(file)
                        player.play()
                        nowPlaying.visible = true
                    }
                }
                UbuntuShape {  // Background so can see text in current state
                    id: genreBg
                    anchors.bottom: parent.bottom
                    color: styleMusic.common.black
                    height: units.gu(6)
                    opacity: .75
                    width: parent.width
                }
                Label {
                    id: genreTotal
                    anchors.top: genreBg.top
                    anchors.topMargin: units.gu(1)
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(1)
                    color: styleMusic.nowPlaying.labelSecondaryColor
                    text: model.total + i18n.tr(" songs")
                    fontSize: "x-small"
                    width: parent.width
                }
                Label {
                    id: genreLabel
                    anchors.top: genreTotal.bottom
                    anchors.topMargin: units.gu(0.5)
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: units.gu(2)
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(1)
                    color: styleMusic.nowPlaying.labelSecondaryColor
                    text: genre === "" ? "None" : genre
                    fontSize: "small"
                    width: parent.width
                }
            }
        }
    }
}
