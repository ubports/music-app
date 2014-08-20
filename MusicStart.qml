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

import QtQuick 2.2
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 0.1
import Ubuntu.Components.Popups 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.MediaScanner 0.1
import Ubuntu.Thumbnailer 0.1
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import "settings.js" as Settings
import "meta-database.js" as Library
import "playlists.js" as Playlists
import "common"

MusicPage {
    id: mainpage
    title: i18n.tr("Music")

    /* Dev button for search.
    Button {
        id: searchButton
        text: i18n.tr("Search")
        anchors.top: parent.top
        anchors.topMargin: units.gu(2)
        anchors.bottom: recentlyPlayed.top
        anchors.bottomMargin: units.gu(1)
        height: units.gu(4)
        onClicked: {
            PopupUtils.open(Qt.resolvedUrl("MusicSearch.qml"), mainView,
            {
                                title: i18n.tr("Search")
            } )
        }
    }
    */
    Flickable{
        id: musicFlickable
        anchors.fill: parent

        width:  mainpage.width
        height: mainpage.height

        contentHeight:  mainView.hasRecent ? recentlyPlayed.height + recentlist.height + genres.height + genrelist.height + albums.height + albumlist.height + units.gu(4)
                                           :  genres.height + genrelist.height + albums.height + albumlist.height + units.gu(3)
        contentWidth: width

        focus: true

        ListItem.Standard {
            id: recentlyPlayed
            Label {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: units.gu(2)
                }
                text: i18n.tr("Recent")
                color: styleMusic.common.music
            }
            visible: mainView.hasRecent
        }

        ListView {
            id: recentlist
            anchors.top: recentlyPlayed.bottom
            anchors.topMargin: units.gu(1)
            width: parent.width
            spacing: units.gu(1)
            height: units.gu(18)
            // TODO: Update when view counts are collected
            model: recentModel.model
            delegate: recentDelegate
            header: Item {
                id: recentSpacer
                width: units.gu(1)
            }
            footer: Item {
                id: clearRecent
                width: recentlist.height - units.gu(2)
                height: width
                visible: mainView.hasRecent && !loading.visible
                Button {
                    id: clearRecentButton
                    anchors.centerIn: parent
                    text: i18n.tr("Clear History")
                    onClicked: {
                        Library.clearRecentHistory()
                        mainView.hasRecent = false
                        recentModel.filterRecent()
                    }
                }
            }
            orientation: ListView.Horizontal
            visible: mainView.hasRecent

            Component {
                id: recentDelegate
                Item {
                    property string title: model.title
                    property string title2: model.title2  !== "Playlist" ? model.title2 : i18n.tr("Playlist")
                    property var covers: type === "playlist" ? Playlists.getPlaylistCovers(title) : [{author: model.title2, album: model.title}]
                    property string type: model.type
                    property string time: model.time
                    property string key: model.key
                    id: recentItem
                    height: recentlist.height - units.gu(1)
                    width: height
                    CoverRow {
                        id: recentShape
                        anchors {
                            top: parent.top
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                        }
                        count: recentItem.covers.length
                        size: recentItem.width
                        covers: recentItem.covers
                        spacing: units.gu(2)
                    }
                    Item {  // Background so can see text in current state
                        id: albumBg
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                        }
                        height: units.gu(6)
                        clip: true
                        UbuntuShape{
                            anchors {
                                bottom: parent.bottom
                                left: parent.left
                                right: parent.right
                            }
                            height: recentShape.height
                            radius: "medium"
                            color: styleMusic.common.black
                            opacity: 0.6
                        }
                    }
                    Label {
                        id: albumArtist
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: units.gu(3)
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(1)
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1)
                        color: styleMusic.common.white
                        elide: Text.ElideRight
                        text: title
                        fontSize: "small"
                        font.weight: Font.DemiBold
                    }
                    Label {
                        id: albumLabel
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(1)
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: units.gu(1)
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1)
                        color: styleMusic.common.white
                        elide: Text.ElideRight
                        text: title2
                        fontSize: "x-small"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (type === "playlist") {
                                albumTracksModel.filterPlaylistTracks(key)
                            } else {
                                songsPage.album = title;
                            }
                            songsPage.genre = undefined;

                            songsPage.line1 = title2
                            songsPage.line2 = title
                            songsPage.covers = recentItem.covers
                            songsPage.isAlbum = (type === "album")
                            songsPage.title = songsPage.isAlbum ? i18n.tr("Album") : i18n.tr("Playlist")

                            mainPageStack.push(songsPage)
                        }

                        // TODO: If http://pad.lv/1354753 is fixed to expose whether the Shape should appear pressed, update this as well.
                        onPressedChanged: recentShape.pressed = pressed
                    }
                }
            }
        }

        ListItem.ThinDivider {
            id: genreDivider
            anchors.top: mainView.hasRecent ? recentlist.bottom : parent.top
        }
        ListItem.Standard {
            id: genres
            anchors.top: genreDivider.bottom
            Label {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: units.gu(2)
                }
                text: i18n.tr("Genres")
                color: styleMusic.common.music
            }
        }
        // TODO: add music genres. frequency of play? most tracks?
        ListView {
            id: genrelist
            width: parent.width
            anchors.top: genres.bottom
            anchors.topMargin: units.gu(1)
            spacing: units.gu(1)
            height: units.gu(18)
            model: GenresModel {
                store: musicStore
            }

            delegate: genreDelegate
            header: Item {
                id: genreSpacer
                width: units.gu(1)
            }
            orientation: ListView.Horizontal

            Component {
                id: genreDelegate
                Item {
                    id: genreItem
                    objectName: "genreItemObject"
                    height: genrelist.height - units.gu(1)
                    width: height

                    Repeater {
                        id: albumGenreModelRepeater
                        model: AlbumsModel {
                            genre: model.genre
                            store: musicStore
                        }

                        delegate: Item {
                            property string author: model.artist
                            property string album: model.title
                        }
                        property var covers: []
                        signal finished()

                        onFinished: {
                            genreShape.count = count
                            genreShape.covers = covers
                        }
                        onItemAdded: {
                            covers.push({author: item.author, album: item.album});

                            if (index === count - 1) {
                                finished();
                            }
                        }
                    }

                    SongsModel {
                        id: songGenreModel
                        genre: model.genre
                        store: musicStore
                    }

                    CoverRow {
                        id: genreShape
                        anchors {
                            top: parent.top
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                        }
                        count: 0
                        size: genreItem.width
                        covers: []
                        spacing: units.gu(2)
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            songsPage.album = undefined
                            songsPage.covers = genreShape.covers
                            songsPage.genre = model.genre
                            songsPage.isAlbum = true
                            songsPage.line1 = i18n.tr("Genre")
                            songsPage.line2 = model.genre
                            songsPage.title = i18n.tr("Genre")

                            mainPageStack.push(songsPage)
                        }

                        // TODO: If http://pad.lv/1354753 is fixed to expose whether the Shape should appear pressed, update this as well.
                        onPressedChanged: genreShape.pressed = pressed
                    }
                    Item {  // Background so can see text in current state
                        id: genreBg
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                        }
                        height: units.gu(5.5)
                        clip: true
                        UbuntuShape{
                            anchors {
                                bottom: parent.bottom
                                left: parent.left
                                right: parent.right
                            }
                            height: genreShape.height
                            radius: "medium"
                            color: styleMusic.common.black
                            opacity: 0.6
                        }
                    }
                    Label {
                        id: genreLabel
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: units.gu(1)
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(1)
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1)
                        color: styleMusic.common.white
                        elide: Text.ElideRight
                        text: model.genre
                        fontSize: "small"
                        font.weight: Font.DemiBold
                    }
                    Label {
                        id: genreTotal
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: units.gu(3)
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(1)
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1)
                        color: styleMusic.common.white
                        elide: Text.ElideRight
                        text: i18n.tr("%1 song", "%1 songs", songGenreModel.rowCount).arg(songGenreModel.rowCount)
                        fontSize: "x-small"
                    }
                }
            }
        }

        ListItem.ThinDivider {
            id: albumsDivider
            anchors.top: genrelist.bottom
        }
        ListItem.Standard {
            id: albums
            Label {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: units.gu(2)
                }
                text: i18n.tr("Albums")
                color: styleMusic.common.music
            }
            anchors.top: albumsDivider.bottom
        }

        ListView {
            id: albumlist
            width: parent.width
            anchors.top: albums.bottom
            anchors.topMargin: units.gu(1)
            spacing: units.gu(1)
            height: units.gu(18)
            model: SortFilterModel {
                id: albumsModelFilter
                property alias rowCount: albumsModel.rowCount
                model: AlbumsModel {
                    id: albumsModel
                    store: musicStore
                }
                sort.property: "title"
                sort.order: Qt.AscendingOrder
            }
            delegate: albumDelegate
            header: Item {
                id: albumSpacer
                width: units.gu(1)
            }
            orientation: ListView.Horizontal

            Component {
                id: albumDelegate
                Item {
                    property string artist: model.artist
                    property string album: model.title
                    property var covers: [{author: model.artist, album: model.title}]

                    id: albumItem
                    objectName: "albumItemObject"
                    height: albumlist.height - units.gu(1)
                    width: height
                    CoverRow {
                        id: albumShape
                        anchors {
                            top: parent.top
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                        }
                        count: albumItem.covers.length
                        size: albumItem.width
                        covers: albumItem.covers
                        spacing: units.gu(2)
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            songsPage.album = album
                            songsPage.covers = covers
                            songsPage.genre = undefined
                            songsPage.isAlbum = true
                            songsPage.line1 = artist
                            songsPage.line2 = album
                            songsPage.title = i18n.tr("Album")

                            mainPageStack.push(songsPage)
                        }

                        // TODO: If http://pad.lv/1354753 is fixed to expose whether the Shape should appear pressed, update this as well.
                        onPressedChanged: albumShape.pressed = pressed
                    }
                    Item {  // Background so can see text in current state
                        id: albumBg
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                        }
                        height: units.gu(6)
                        clip: true
                        UbuntuShape{
                            anchors {
                                bottom: parent.bottom
                                left: parent.left
                                right: parent.right
                            }
                            height: albumShape.height
                            radius: "medium"
                            color: styleMusic.common.black
                            opacity: 0.6
                        }
                    }
                    Label {
                        id: albumLabel
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: units.gu(1)
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(1)
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1)
                        color: styleMusic.common.white
                        elide: Text.ElideRight
                        text: artist
                        fontSize: "x-small"
                    }
                    Label {
                        id: albumLabel2
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: units.gu(3)
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(1)
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1)
                        color: styleMusic.common.white
                        elide: Text.ElideRight
                        text: album
                        fontSize: "small"
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }
}
