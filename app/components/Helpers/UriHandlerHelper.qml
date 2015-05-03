/*
 * Copyright (C) 2013, 2014, 2015
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
import Ubuntu.Components 1.2
import "../"
import "../../logic/stored-request.js" as StoredRequest


Item {
    id: uriHandler

    Connections {
        target: UriHandler

        onOpened: {
            for (var i=0; i < uris.length; i++) {
                console.debug("URI=" + uris[i])
                uriHandler.process(uris[i], i === 0);
            }
        }
    }

    function processAlbum(uri) {
        // Stop queue loading in the background
        queueLoaderWorker.canLoad = false

        if (queueLoaderWorker.processing > 0) {
            waitForWorker.workerStop(queueLoaderWorker, processAlbum, [uri])
            return;
        }

        selectedAlbum = true;
        var split = uri.split("/");

        if (split.length < 2) {
            console.debug("Unknown artist-album " + uri + ", skipping")
            return;
        }

        // Filter by artist and album
        songsAlbumArtistModel.albumArtist = decodeURIComponent(split[0]);
        songsAlbumArtistModel.album = decodeURIComponent(split[1]);
    }

    function processFile(uri, play) {
        // Stop queue loading in the background
        queueLoaderWorker.canLoad = false

        if (queueLoaderWorker.processing > 0) {
            waitForWorker.workerStop(queueLoaderWorker, processFile, [uri, play])
            return;
        }

        uri = decodeURIComponent(uri);

        // Lookup track in songs model
        var track = musicStore.lookup(decodeURIComponent(uri));

        if (!track) {
            console.debug("Unknown file " + uri + ", skipping")
            return;
        }

        if (play) {
            // clear play queue
            trackQueue.clear()
        }

        // enqueue
        trackQueue.append(makeDict(track));

        // play first URI
        if (play) {
            trackQueueClick(trackQueue.model.count - 1);
        }
    }

    function process(uri, play) {
        if (firstRun) {
            console.debug("Delaying uri call", uri)
            StoredRequest.store(function() { return process(uri, play); })
        } else if (uri.indexOf("album:///") === 0) {
            processAlbum(uri.substring(9));
        } else if (uri.indexOf("file://") === 0) {
            processFile(uri.substring(7), play);
        } else if (uri.indexOf("music://") === 0) {
            processFile(uri.substring(8), play);
        } else {
            console.debug("Unsupported URI " + uri + ", skipping")
        }
    }
}
