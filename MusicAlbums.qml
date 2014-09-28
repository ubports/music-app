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
import "common"


MusicPage {
    id: albumsPage
    objectName: "albumsPage"
    title: i18n.tr("Albums")

    CardView {
        id: albumCardView
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
        delegate: Card {
            id: albumCard
            imageSource: model.art
            objectName: "albumsPageGridItem" + index
            primaryText: model.title
            secondaryText: model.artist

            onClicked: {
                songsPage.album = model.title;
                songsPage.covers = [{art: model.art}]
                songsPage.genre = undefined
                songsPage.isAlbum = true
                songsPage.line1 = model.artist
                songsPage.line2 = model.title
                songsPage.title = i18n.tr("Album")

                mainPageStack.push(songsPage)
            }
        }
    }
}
