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
import QtQuick.LocalStorage 2.0
import "meta-database.js" as Library
import "playlists.js" as Playlists

Item {
    id: libraryListModelItem
    property alias count: libraryModel.count
    property ListModel model : ListModel {
        id: libraryModel
        property var linkLibraryListModel: libraryListModelItem
    }
    property var param: null
    property var query: null
    /* Pretent to be like a mediascanner2 listmodel */
    property alias rowCount: libraryModel.count

    property alias canLoad: worker.canLoad
    property alias preLoadComplete: worker.preLoadComplete
    property alias syncFactor: worker.syncFactor
    property alias workerComplete: worker.completed
    property alias workerList: worker.list

    function get(index, role) {
        return model.get(index);
    }

    WorkerModelLoader {
        id: worker
        model: libraryListModelItem.model
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

    function filterPlaylists() {
        console.log("called LibraryListModel::filterPlaylist()")

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
}
