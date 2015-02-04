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
import "../logic/meta-database.js" as Library
import "../components"

MusicPage {
    id: artistViewPage
    objectName: "artistViewPage"
    visible: false

    property string artist: ""
    property var covers: []
    property bool loaded: false  // used to detect difference between first and further loads

    CardView {
        id: artistAlbumView
        anchors {
            fill: parent
        }
        getter: function (i) {
            return {
                "art": albumsModel.get(i, AlbumsModel.RoleArt),
                "artist": albumsModel.get(i, AlbumsModel.RoleArtist),
                "title": albumsModel.get(i, AlbumsModel.RoleTitle),
            };
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
                        elide: Text.ElideRight
                        height: parent.height
                        horizontalAlignment: Text.AlignHCenter
                        // TRANSLATORS: this appears in a button with limited space (around 14 characters)
                        text: i18n.tr("Shuffle")
                        verticalAlignment: Text.AlignVCenter
                        width: parent.width - units.gu(2)
                    }
                    onClicked: shuffleModel(songArtistModel)
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
                        elide: Text.ElideRight
                        height: parent.height
                        horizontalAlignment: Text.AlignHCenter
                        // TRANSLATORS: this appears in a button with limited space (around 14 characters)
                        text: i18n.tr("Queue all")
                        verticalAlignment: Text.AlignVCenter
                        width: parent.width - units.gu(2)
                    }
                    onClicked: addQueueFromModel(songArtistModel)
                }
                Button {
                    id: playRow
                    color: UbuntuColors.green
                    height: units.gu(4)
                    // TRANSLATORS: this appears in a button with limited space (around 14 characters)
                    text: i18n.tr("Play all")
                    width: units.gu(15)
                    onClicked: trackClicked(songArtistModel, 0, true)
                }
            }
            coverSources: artistViewPage.covers
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
                    text: artist != "" ? artist : i18n.tr("Unknown Artist")
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
                    text: i18n.tr("%1 album", "%1 albums", albumsModel.count).arg(albumsModel.count)
                }
            }

            SongsModel {
                id: songArtistModel
                albumArtist: artistViewPage.artist
                store: musicStore
            }
        }
        itemWidth: units.gu(12)
        model: AlbumsModel {
            id: albumsModel
            albumArtist: artistViewPage.artist
            store: musicStore
            onStatusChanged: {
                if (albumsModel.status === SongsModel.Ready && loaded && albumsModel.count === 0) {
                    mainPageStack.popPage(artistViewPage)
                }
            }
        }
        delegate: Card {
            id: albumCard
            coverSources: [{art: model.art}]
            objectName: "albumsPageGridItem" + index
            primaryText: model.title != "" ? model.title : i18n.tr("Unknown Album")
            secondaryTextVisible: false

            onClicked: {
                var comp = Qt.createComponent("SongsView.qml")
                var songsPage = comp.createObject(mainPageStack,
                                                  {
                                                      "album": model.title,
                                                      "artist": model.artist,
                                                      "covers": [{art: model.art}],
                                                      "isAlbum": true,
                                                      "genre": undefined,
                                                      "title": i18n.tr("Album"),
                                                      "line1": model.artist != "" ? model.artist : i18n.tr("Unknown Artist"),
                                                      "line2": model.title != "" ? model.title : i18n.tr("Unknown Album"),
                                                  });

                if (songsPage == null) {  // Error Handling
                    console.log("Error creating object");
                }

                mainPageStack.push(songsPage)
            }
        }
    }

    Component.onCompleted: loaded = true
}

