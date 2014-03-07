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
    property bool canLoad: true
    property bool preLoadComplete: false

    onCanLoadChanged: {
        /* If canLoad has been set back to true then check if there are any
          remaining items to load in the model */
        if (canLoad && worker.list !== null && !worker.completed)
        {
            worker.process();
        }
    }

    WorkerScript {
         id: worker
         source: "worker-library-loader.js"

         property bool completed: false
         property int i: 0
         property var list: null

         onListChanged: {
             reset();
             clear();
         }

         onMessage: {
             if (i === 0)
             {
                 preLoadComplete = true;
             }

             if (canLoad)  // pause if the model is not allowed to load
             {
                 process();
             }
         }

         function reset()
         {
             i = 0;
             completed = false;
         }

         // Add the next item in the list to the model otherwise set complete
         function process()
         {
             if (worker.i < worker.list.length)
             {
                 console.log(JSON.stringify(worker.list[worker.i]));
                 worker.sendMessage({'add': worker.list[worker.i],
                                     'model': libraryModel});
                 worker.i++;
             }
             else
             {
                 worker.completed = true;
             }
         }
    }

    function indexOf(file)
    {
        file = file.toString();

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
        console.log("called LibraryListModel::populate()")

        // Save query for queue
        query = Library.getAll
        param = null

        worker.list = Library.getAll();
    }

    function filterArtists() {
        console.log("called LibraryListModel::filterArtists()")

        // Save query for queue
        query = Library.getArtists
        param = null

        worker.list = Library.getArtists();
    }

    function filterArtistTracks(artist) {
        console.log("called LibraryListModel::filterArtistTracks()")

        // Save query for queue
        query = Library.getArtistTracks
        param = artist

        worker.list = Library.getArtistTracks(artist);
    }

    function filterArtistAlbums(artist) {
        console.log("called LibraryListModel::filterArtistAlbums()")

        // Save query for queue
        query = Library.getArtistAlbums
        param = artist

        worker.list = Library.getArtistAlbums(artist);
    }

    function filterAlbums() {
        console.log("called LibraryListModel::filterAlbums()")

        // Save query for queue
        query = Library.getAlbums
        param = null

        worker.list = Library.getAlbums();
    }

    function filterAlbumTracks(album) {
        console.log("called LibraryListModel::filterAlbumTracks()")

        // Save query for queue
        query = Library.getAlbumTracks
        param = album

        worker.list = Library.getAlbumTracks(album);
    }

    function filterPlaylists() {
        console.log("called LibraryListModel::filterPlaylistTracks()")

        // Save query for queue
        query = Playlists.getPlaylists
        param = null

        worker.list = Playlists.getPlaylists();
    }

    function filterPlaylistTracks(playlist) {
        console.log("called LibraryListModel::filterPlaylistTracks()")

        // Save query for queue
        query = Playlists.getPlaylistTracks
        param = playlist

        worker.list = Playlists.getPlaylistTracks(playlist);
    }

    function filterRecent() {
        console.log("called LibraryListModel::filterRecent()")

        // Save query for queue
        query = Library.getRecent
        param = null

        worker.list = Library.getRecent();
    }

    function filterGenres() {
        console.log("called LibraryListModel::filterGenres()")

        // Save query for queue
        query = Library.getGenres
        param = null

        worker.list = Library.getGenres();
    }

    function filterGenreTracks(genre) {
        console.log("called LibraryListModel::filterGenreTracks()")

        // Save query for queue
        query = Library.getGenreTracks
        param = genre

        worker.list = Library.getGenreTracks(genre);
    }

    function clear() {
        if (worker.list !== null)
        {
            worker.sendMessage({'clear': true, 'model': libraryModel})
        }
    }

    function filterSearch(searchQuery) {
        query = Library.search
        param = searchQuery
        worker.list = Library.search(searchQuery)
    }
}
