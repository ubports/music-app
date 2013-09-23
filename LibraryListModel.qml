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
import "playlists.js" as Playlists

Item {
    property ListModel model : ListModel { id: libraryModel }
    property alias count: libraryModel.count
    property var query: null
    property var param: null

    WorkerScript {
         id: worker
         source: "worker-library-loader.js"
    }

    function indexOf(file)
    {
        if (file.indexOf("file://") == 0)
        {
            file = file.slice(7, file.length)
        }

        for (var i=0; i < model.count; i++)
        {
            if (model.get(i).file == file)
            {
                return i;
            }
        }

        return -1;
    }

    function populate() {
        worker.sendMessage({'clear': true, 'model': libraryModel})

        console.log("called LibraryListModel::populate()")

        // Save query for queue
        query = Library.getAll
        param = null

        var library = Library.getAll()

        for ( var key in library ) {
            var add = library[key];
            console.log(JSON.stringify(add))
            worker.sendMessage({'add': add, 'model': libraryModel})
        }
    }

    function filterArtists() {
        worker.sendMessage({'clear': true, 'model': libraryModel})

        console.log("called LibraryListModel::filterArtists()")

        // Save query for queue
        query = Library.getArtists
        param = null

        var library = Library.getArtists()

        for ( var key in library ) {
            var add = library[key];
            console.log("add.artist: "+add.artist)
            console.log(JSON.stringify(add))
            worker.sendMessage({'add': add, 'model': libraryModel})
        }
    }

    function filterArtistTracks(artist) {
        worker.sendMessage({'clear': true, 'model': libraryModel})

        console.log("called LibraryListModel::filterArtistTracks()")

        // Save query for queue
        query = Library.getArtistTracks
        param = artist

        var library = Library.getArtistTracks(artist)

        for ( var key in library ) {
            var add = library[key];
            console.log(JSON.stringify(add))
            worker.sendMessage({'add': add, 'model': libraryModel})
        }
    }

    function filterAlbums() {
        worker.sendMessage({'clear': true, 'model': libraryModel})

        console.log("called LibraryListModel::filterAlbums()")

        // Save query for queue
        query = Library.getAlbums
        param = null

        var library = Library.getAlbums()

        for ( var key in library ) {
            var add = library[key];
            console.log("add.album: "+add.album)
            console.log(JSON.stringify(add))
            worker.sendMessage({'add': add, 'model': libraryModel})
        }
    }

    function filterAlbumTracks(album) {
        worker.sendMessage({'clear': true, 'model': libraryModel})

        console.log("called LibraryListModel::filterAlbumTracks()")

        // Save query for queue
        query = Library.getAlbumTracks
        param = album

        var library = Library.getAlbumTracks(album)

        for ( var key in library ) {
            var add = library[key];
            console.log(JSON.stringify(add))
            worker.sendMessage({'add': add, 'model': libraryModel})
        }
    }

    function filterPlaylistTracks(playlist) {
        worker.sendMessage({'clear': true, 'model': libraryModel})

        console.log("called LibraryListModel::filterPlaylistTracks()")

        // Save query for queue
        query = Playlists.getPlaylistTracks
        param = playlist

        var tracks = Playlists.getPlaylistTracks(playlist)

        for ( var key in tracks ) {
            var add = tracks[key];
            console.log(JSON.stringify(add))
            worker.sendMessage({'add': add, 'model': libraryModel})
        }
    }

    function filterGenres() {
        worker.sendMessage({'clear': true, 'model': libraryModel})

        console.log("called LibraryListModel::filterGenres()")

        // Save query for queue
        query = Library.getGenres
        param = null

        var library = Library.getGenres()

        for ( var key in library ) {
            var add = library[key];
            console.log("add.genre: "+add.Genre)
            console.log(JSON.stringify(add))
            worker.sendMessage({'add': add, 'model': libraryModel})
        }
    }

    function filterGenreTracks(genre) {
        worker.sendMessage({'clear': true, 'model': libraryModel})

        console.log("called LibraryListModel::filterGenreTracks()")

        // Save query for queue
        query = Library.getGenreTracks
        param = genre

        var library = Library.getGenreTracks(genre)

        for ( var key in library ) {
            var add = library[key];
            console.log(JSON.stringify(add))
            worker.sendMessage({'add': add, 'model': libraryModel})
        }
    }
}
