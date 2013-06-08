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
import QtQuick.LocalStorage 2.0
import "meta-database.js" as Library

Item {
    property ListModel model : ListModel { id: libraryModel }
    property alias count: libraryModel.count

    function populate() {
        libraryModel.clear();
        console.log("called LibraryListModel::populate()")

        var library = Library.getAll()

        for ( var key in library ) {
            var add = library[key];
            console.log(JSON.stringify(add))
            libraryModel.append( add );
        }
    }

    function filterArtists() {
        libraryModel.clear();
        console.log("called LibraryListModel::filterArtists()")

        var library = Library.getAll()

        var added = new Array
        for ( var key in library ) {
            var add = library[key];
            console.log("add.artist: "+add.artist)
            console.log(JSON.stringify(add))
            if (added.indexOf(add.artist) === -1) {
                libraryModel.append( add );
                added.push(add.artist)
            }
        }
    }

    function filterAlbums() {
        libraryModel.clear();
        console.log("called LibraryListModel::filterAlbums()")

        var library = Library.getAll()

        var added = new Array
        for ( var key in library ) {
            var add = library[key];
            console.log("add.album: "+add.album)
            console.log(JSON.stringify(add))
            if (added.indexOf(add.album) === -1) {
                libraryModel.append( add );
                added.push(add.album)
            }
        }
    }
}
