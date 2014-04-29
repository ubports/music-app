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
import Ubuntu.MediaScanner 0.1
import Ubuntu.Thumbnailer 0.1
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import "settings.js" as Settings
import "meta-database.js" as Library
import "playlists.js" as Playlists
import "common"

Page {
    id: mainpage
    title: i18n.tr("Music")

    onVisibleChanged: {
        if (visible === true)
        {
            musicToolbar.setPage(mainpage);
        }
    }

    /* Dev button for search.
    Button {
        id: searchButton
        text: "Search"
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

        // TODO: uncomment when genre is reenabled
        /*
        contentHeight:  mainView.hasRecent ? recentlyPlayed.height + recentlist.height + genres.height + genrelist.height + albums.height + albumlist.height + units.gu(4)
                                           :  genres.height + genrelist.height + albums.height + albumlist.height + units.gu(3)
        */
        contentHeight:  mainView.hasRecent ? recentlyPlayed.height + recentlist.height + albums.height + albumlist.height + units.gu(4)
                                           :  albums.height + albumlist.height + units.gu(3)
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
                id: spacer
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
                    text: "Clear History"
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
                    property string title2: model.title2
                    property var covers: type === "playlist" ? Playlists.getPlaylistCovers(title) : [Library.getAlbumCover(title)]
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
                    UbuntuShape {  // Background so can see text in current state
                        id: albumBg2
                        anchors.bottom: parent.bottom
                        color: styleMusic.common.black
                        height: units.gu(4)
                        width: parent.width
                    }
                    Rectangle {  // Background so can see text in current state
                        id: albumBg
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: units.gu(2)
                        color: styleMusic.common.black
                        height: units.gu(3)
                        width: parent.width
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
                    }
                    Label {
                        id: albumLabel
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(1)
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: units.gu(1)
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1)
                        color: styleMusic.nowPlaying.labelSecondaryColor
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
                                albumTracksModel.filterAlbumTracks(title)
                            }

                            songsSheet.line1 = title2
                            songsSheet.line2 = title
                            songsSheet.covers =  recentItem.covers
                            PopupUtils.open(songsSheet.sheet)
                            songsSheet.isAlbum = (type === "album")
                        }
                    }
                }
            }
        }

        // TODO: remove genre for now as not in mediascanner2
        /*
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
                    property string artist: model.artist
                    property string album: model.album
                    property string title: model.title
                    property var covers: Library.getGenreCovers(model.genre)
                    property string length: model.length
                    property string file: model.file
                    property string year: model.year
                    property string genre: model.genre

                    id: genreItem
                    objectName: "genreItemObject"
                    height: genrelist.height - units.gu(1)
                    width: height
                    CoverRow {
                        id: genreShape
                        anchors {
                            top: parent.top
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                        }
                        count: genreItem.covers.length
                        size: genreItem.width
                        covers: genreItem.covers
                        spacing: units.gu(2)
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            albumTracksModel.filterGenreTracks(genre)
                            songsSheet.line1 = "Genre"
                            songsSheet.line2 = genre
                            songsSheet.isAlbum = false
                            songsSheet.covers =  covers
                            PopupUtils.open(songsSheet.sheet)
                        }
                    }
                    Rectangle {  // Background so can see text in current state
                        id: genreBg
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: units.gu(2)
                        color: styleMusic.common.black
                        height: units.gu(3)
                        width: parent.width
                    }
                    UbuntuShape {  // Background so can see text in current state
                        id: genreBg2
                        anchors.bottom: parent.bottom
                        color: styleMusic.common.black
                        height: units.gu(4)
                        width: parent.width
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
                        text: genre
                        fontSize: "small"
                    }
                    Label {
                        id: genreTotal
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: units.gu(3)
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(1)
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1)
                        color: styleMusic.nowPlaying.labelSecondaryColor
                        elide: Text.ElideRight
                        text: i18n.tr("%1 song", "%1 songs", model.total).arg(model.total)
                        fontSize: "x-small"
                    }
                }
            }
        }
        */

        ListItem.ThinDivider {
            id: albumsDivider
            //anchors.top: genrelist.bottom
            anchors.top: mainView.hasRecent ? recentlist.bottom : parent.top
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
            model: AlbumsModel {
                id: albumsModel
                store: musicStore
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
                    property var covers: [model.art]

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
                            albumTracksModel.filterAlbumTracks(album)
                            songsSheet.line1 = artist
                            songsSheet.line2 = album
                            songsSheet.isAlbum = true
                            songsSheet.covers =  covers
                            PopupUtils.open(songsSheet.sheet)
                        }
                    }
                    Rectangle {  // Background so can see text in current state
                        id: albumBg
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: units.gu(2)
                        color: styleMusic.common.black
                        height: units.gu(3)
                        width: parent.width
                    }
                    UbuntuShape {  // Background so can see text in current state
                        id: albumBg2
                        anchors.bottom: parent.bottom
                        color: styleMusic.common.black
                        height: units.gu(4)
                        width: parent.width
                    }
                    Label {
                        id: albumLabel
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: units.gu(1)
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(1)
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1)
                        color: styleMusic.nowPlaying.labelSecondaryColor
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
                    }
                }
            }
        }
    }
}
