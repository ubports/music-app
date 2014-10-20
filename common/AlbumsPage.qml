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
import Ubuntu.Components.Popups 1.0
import Ubuntu.Components.ListItems 1.0 as ListItem
import Ubuntu.MediaScanner 0.1
import Ubuntu.Thumbnailer 0.1
import QtQuick.LocalStorage 2.0
import "../meta-database.js" as Library

MusicPage {
    id: albumStackPage
    objectName: "albumsArtistPage"
    visible: false

    property string artist: ""
    property var covers: []

    CardView {
        id: artistAlbumView
        anchors {
            fill: parent
        }
        header: BlurredHeader {
            rightColumn: Column {
                spacing: units.gu(2)
                Button {
                    id: shuffleRow
                    height: units.gu(4)
                    strokeColor: UbuntuColors.green
                    width: units.gu(15)
                    Text {
                        anchors {
                            centerIn: parent
                        }
                        color: "white"
                        text: i18n.tr("Shuffle")
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: shuffleModel(songArtistModel)
                    }
                }
                Button {
                    id: queueAllRow
                    height: units.gu(4)
                    strokeColor: UbuntuColors.green
                    width: units.gu(15)
                    Text {
                        anchors {
                            centerIn: parent
                        }
                        color: "white"
                        text: i18n.tr("Queue all")
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: addQueueFromModel(songArtistModel)
                    }
                }
                Button {
                    id: playRow
                    color: UbuntuColors.green
                    height: units.gu(4)
                    text: i18n.tr("Play all")
                    width: units.gu(15)
                    MouseArea {
                        anchors.fill: parent
                        onClicked: trackClicked(songArtistModel, 0, true)
                    }
                }
            }
            coverSources: albumStackPage.covers
            height: units.gu(30)
            bottomColumn: Column {
                Label {
                    id: artistLabel
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    color: styleMusic.common.music
                    elide: Text.ElideRight
                    fontSize: "x-large"
                    maximumLineCount: 1
                    objectName: "artistLabel"
                    text: artist
                    wrapMode: Text.NoWrap
                }

                Item {
                    height: units.gu(1)
                    width: parent.width
                }

                Label {
                    id: artistCount
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    color: styleMusic.common.subtitle
                    elide: Text.ElideRight
                    fontSize: "small"
                    maximumLineCount: 1
                    text: i18n.tr("%1 album", "%1 albums", artistsModel.count).arg(artistsModel.count)
                }
            }

            SongsModel {
                id: songArtistModel
                albumArtist: albumStackPage.artist
                store: musicStore
            }
        }
        itemWidth: units.gu(12)
        model: AlbumsModel {
            id: artistsModel
            albumArtist: albumStackPage.artist
            store: musicStore
        }
        delegate: Card {
            id: albumCard
            coverSources: [{art: model.art}]
            objectName: "albumsPageGridItem" + index
            primaryText: model.title
            secondaryText: model.artist

            onClicked: {
                songsPage.album = model.title;

                songsPage.line1 = model.artist
                songsPage.line2 = model.title
                songsPage.isAlbum = true
                songsPage.covers = [{art: model.art}]
                songsPage.genre = undefined
                songsPage.title = i18n.tr("Album")

                mainPageStack.push(songsPage)
            }
        }
    }
}

