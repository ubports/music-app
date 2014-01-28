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
    title: i18n.tr("Artists")

    onVisibleChanged: {
        if (visible === true)
        {
            musicToolbar.setPage(mainpage);
        }
    }

    MusicSettings {
        id: musicSettings
    }

    ListView {
        id: artistlist
        anchors.fill: parent
        anchors.bottomMargin: musicToolbar.mouseAreaOffset + musicToolbar.minimizedHeight
        model: artistModel.model
        delegate: artistDelegate

        Component {
            id: artistDelegate

            ListItem.Standard {
                id: track
                property string artist: model.artist
                height: styleMusic.common.itemHeight

                CoverRow {
                    id: coverRow
                    anchors {
                        top: parent.top
                        left: parent.left
                        margins: units.gu(1)
                    }
                    count: parseInt(Library.getArtistCovers(artist).length)
                    size: styleMusic.common.albumSize
                    covers: Library.getArtistCovers(artist)
                }

                Label {
                    id: trackArtistAlbum
                    wrapMode: Text.NoWrap
                    maximumLineCount: 2
                    fontSize: "medium"
                    color: styleMusic.common.music
                    anchors {
                        left: coverRow.right
                        leftMargin: units.gu(2)
                        top: parent.top
                        topMargin: units.gu(2)
                        right: parent.right
                        rightMargin: units.gu(1.5)
                    }
                    elide: Text.ElideRight
                    text: artist
                }

                Label {
                    id: trackArtistAlbums
                    wrapMode: Text.NoWrap
                    maximumLineCount: 2
                    fontSize: "x-small"
                    anchors {
                        left: trackArtistAlbum.left
                        top: trackArtistAlbum.bottom
                        topMargin: units.gu(1)
                        right: parent.right
                        rightMargin: units.gu(1.5)
                    }
                    elide: Text.ElideRight
                    // model for number of albums?
                    text: i18n.tr("%1 album", "%1 albums", Library.getArtistAlbumCount(artist)).arg(Library.getArtistAlbumCount(artist))
                }

                Label {
                    id: trackArtistAlbumTracks
                    wrapMode: Text.NoWrap
                    maximumLineCount: 2
                    fontSize: "x-small"
                    anchors {
                        left: trackArtistAlbum.left
                        top: trackArtistAlbums.bottom
                        topMargin: units.gu(1)
                        right: parent.right
                        rightMargin: units.gu(1.5)
                    }
                    elide: Text.ElideRight
                    text: i18n.tr("%1 song", "%1 songs", Library.getArtistTracks(artist).length).arg(Library.getArtistTracks(artist).length)
                }
                onFocusChanged: {
                }
                MouseArea {
                    anchors.fill: parent
                    onDoubleClicked: {
                    }
                    onPressAndHold: {
                    }
                    onClicked: {
                        artistAlbumsModel.filterArtistAlbums(artist)
                        artistSheet.artist = artist
                        PopupUtils.open(artistSheet.sheet)
                    }
                }
                Component.onCompleted: {
                }
            }
        }
    }
}

