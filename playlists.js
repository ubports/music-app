/*
 * Copyright (C) 2013   Daniel Holm <d.holmen@gmail.com>
 *                      Victor Thompson <victor.thompson@gmail.com>
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

// LEGACY Helper for the playlists database
function getPlaylistsDatabase() {
    return LocalStorage.openDatabaseSync("music-app-playlists", "1.0",
                                         "StorageDatabase", 1000000)
}

// CURRENT database for individual playlists - the one witht the actual tracks in
function getPlaylistDatabase() {
    return LocalStorage.openDatabaseSync("music-app-playlist", "",
                                         "StorageDatabase", 1000000)
}

// same thing for individal playlists
function initializePlaylist() {
    var db = getPlaylistDatabase()
    console.debug("Playlist DB is version " + db.version)

    var playlists = {}  // read old playlists into here

    // does the user have the latest db scheme?
    if (db.version === "1.0" || db.version === "1.1") {
        db.changeVersion(db.version, "1.2", function (t) {
            t.executeSql('DROP TABLE IF EXISTS playlist;') // TODO: later, if we need a db version update, we should keep earlier settings. This is just for now.
            console.debug("DB: Changing version of playlist db to 1.2 by dropping it.")
        })
    }

    if (db.version === "1.2" || db.version === "") {
        var oldDb = getPlaylistsDatabase();
        var oldPlaylists = [];

        oldDb.transaction(function (tx) {
            try {
                var rs = tx.executeSql('SELECT name FROM playlists;');

                for (var i=0; i < rs.rows.length; i++) {
                    oldPlaylists.push(rs.rows.item(i).name)
                }
            }
            catch (err) {

            }

            // Delete old extra db
            tx.executeSql('DROP TABLE IF EXISTS playlists;');
        });


        db.changeVersion(db.version, "1.3", function (tx) {
            var rs;

            try {
                rs = tx.executeSql('SELECT * FROM playlist ORDER BY id');
            }
            catch (err) {
                rs = {rows: []}
            }

            console.debug("DB: Changing version of playlist db to 1.3, migrating", rs.rows.length, "tracks")
            console.debug("Old playlists", JSON.stringify(oldPlaylists))

            for (var i=0; i < rs.rows.length; i++) {
                var dbItem = rs.rows.item(i);

                if (oldPlaylists.indexOf(dbItem.playlist) === -1) {
                    console.debug("Skipping playlist", dbItem.playlist, "as it was deleted")
                    continue;
                }

                if (playlists[dbItem.playlist] === undefined) {
                    playlists[dbItem.playlist] = [];
                }

                playlists[dbItem.playlist].push({filename: dbItem.track,
                                                 title: dbItem.title,
                                                 author: dbItem.artist,
                                                 album: dbItem.album
                                                })
            }

            tx.executeSql('DROP TABLE IF EXISTS playlist;')
        })
    }

    db.transaction(function (tx) {
        tx.executeSql('CREATE TABLE IF NOT EXISTS playlist(name TEXT PRIMARY KEY, FOREIGN KEY (name) REFERENCES track(playlist));')
        tx.executeSql('CREATE TABLE IF NOT EXISTS track(i INTEGER NOT NULL, playlist TEXT NOT NULL, filename TEXT, title TEXT, author TEXT, album TEXT, PRIMARY KEY (playlist, i), FOREIGN KEY (playlist) REFERENCES tracks(playlist));')

        console.debug("DB: Restore", JSON.stringify(playlists))

        // Restore old db data if exists
        for (var playlist in playlists) {
            console.debug("Adding playlist", playlist)

            addPlaylist(playlist, tx)

            for (var i=0; i < playlists[playlist].length; i++) {
                console.debug("Adding track to playlist", JSON.stringify(playlists[playlist][i]))

                addToPlaylist(playlist, playlists[playlist][i], tx)
            }
        }
    })

}

function addPlaylist(name, tx) {
    if (tx === undefined) {
        var db = getPlaylistDatabase()

        db.transaction(function (tx) {
            return addPlaylist(name, tx)
        });
    }
    else {
        var rs = false

        console.debug("Add new playlists:", name)

        try {
            rs = tx.executeSql('INSERT INTO playlist VALUES (?);',
                               [name]).rowsAffected > 0
        } catch (e) {
            rs = false
        }

        return rs
    }
}

function addToPlaylist(playlist, model, tx) {
    if (tx === undefined) {
        var db = getPlaylistDatabase()

        db.transaction(function (tx) {
            return addToPlaylist(playlist, model, tx)
        });
    }
    else {
        var rs = false

        // Generate new index number if records exist, otherwise use 0
        rs = tx.executeSql('SELECT MAX(i) FROM track WHERE playlist=?;',
                           playlist)

        var index = isNaN(rs.rows.item(0)["MAX(i)"]) ? 0 : rs.rows.item(
                                                           0)["MAX(i)"] + 1

        // Add track to db
        rs = tx.executeSql(
                    'INSERT OR REPLACE INTO track VALUES (?,?,?,?,?,?);',
                    [index, playlist, model.filename, model.title, model.author, model.album]).rowsAffected > 0

        return rs
    }

}

function getPlaylists() {
    // returns playlists with count and 4 covers
    var db = getPlaylistDatabase()
    var res = []

    try {
        db.transaction(function (tx) {
            var rs = tx.executeSql('SELECT * FROM playlist;')

            for (var i = 0; i < rs.rows.length; i++) {
                var dbItem = rs.rows.item(i)

                res.push({
                             name: dbItem.name,
                             count: getPlaylistCount(dbItem.name, tx)
                         })
            }
        })
    } catch (e) {
        return []
    }

    return res
}

function getPlaylistTracks(playlist) {
    var db = getPlaylistDatabase()
    var res = []

    try {
        db.transaction(function (tx) {
            var rs = tx.executeSql('SELECT * FROM track WHERE playlist=?;',
                                   [playlist])
            for (var j = 0; j < rs.rows.length; j++) {
                var dbItem = rs.rows.item(j)

                res.push({
                             i: dbItem.i,
                             filename: dbItem.filename,
                             title: dbItem.title,
                             author: dbItem.author,
                             album: dbItem.album // FIXME: need to construct art: ?
                         })
            }
        })
    } catch (e) {
        return []
    }

    return res
}

function getPlaylistCount(playlist, tx) {
    if (tx === undefined) {
        var db = getPlaylistDatabase()

        db.transaction(function (tx) {
            return getPlaylistCount(playlist, tx)
        });
    }
    else {
        var res = 0

        try {
            res = tx.executeSql('SELECT * FROM track WHERE playlist=?;',
                                [playlist]).rows.length
        } catch (e) {
            return res
        }

        return res
    }
}

function getPlaylistCovers(playlist, max) {
    var db = getPlaylistDatabase()
    var res = []

    // Get a list of unique covers for the playlist
    try {
        db.transaction(function (tx) {
            var rs = tx.executeSql("SELECT * FROM track WHERE playlist=?;",
                                   [playlist])

            for (var i = 0; i < rs.rows.length
                 && i < (max || rs.rows.length); i++) {
                var row = {
                    author: rs.rows.item(i).author,
                    album: rs.rows.item(i).album
                }

                if (res.indexOf(row) === -1) {
                    res.push(row)
                }
            }
        })
    } catch (e) {
        return []
    }

    return res
}

function renamePlaylist(from, to) {
    var db = getPlaylistDatabase()


    db.transaction(function (tx) {
        addPlaylist(to, tx)

        tx.executeSql('UPDATE track SET playlist=? WHERE playlist=?;',
                      [to, from])

        removePlaylist(from, tx)
    })

}

function removePlaylist(playlist) {
    var db = getPlaylistDatabase()
    var res = false

    db.transaction(function (tx) {
        tx.executeSql('DELETE FROM track WHERE playlist=?;', [playlist])
        res = tx.executeSql('DELETE FROM playlist WHERE name=?;',
                            [playlist]).rowsAffected > 0
    })

    return res
}

function removeFromPlaylist(playlist, index) {
    var db = getPlaylistDatabase()
    var res = false

    db.transaction(function (tx) {
        res = tx.executeSql('DELETE FROM track WHERE playlist=? AND i=?;',
                            [playlist, index]).rowsAffected > 0

        reorder(playlist, "remove", tx)
    })

    return res
}

function reorder(playlist, type, tx) {
    var db = getPlaylistDatabase()

    if (tx === undefined) {
        db.transaction(function (tx) {
            return reorder(playlist, type, tx)
        });
    }
    else {
        var res = tx.executeSql(
                    "SELECT * FROM track WHERE i > ? AND playlist=? ORDER BY i ASC;",
                    [-1, playlist])
        var i;

        if (type === "remove") {
            for (i = 0; i < res.rows.length; i++) {
                tx.executeSql('UPDATE track SET i=? WHERE i=? AND playlist=?;',
                              [i, res.rows.item(i).i, playlist])
            }
        }
        else {  // insert -1 at {type}, shuffle >= {type} + 1 and put -1 in the gap
            for (i=res.rows.item(res.rows.length - 1).i; i >= type; i--) {
                tx.executeSql('UPDATE track SET i=i + 1 WHERE i >= ? AND playlist=?;',
                              [i, playlist])
            }

            tx.executeSql('UPDATE track SET i=? WHERE i=? AND playlist=?;',
                          [type, -1, playlist])
        }
    }
}

function move(playlist, from, to) {
    var db = getPlaylistDatabase()

    console.debug("Move", playlist, from, to)

    db.transaction(function (tx) {
        // Hide track from list
        tx.executeSql('UPDATE track SET i=? WHERE i=? AND playlist=?;',
                      [-1, from, playlist])

        reorder(playlist, "remove", tx) // 'remove' resorting the queue
        reorder(playlist, to, tx) // insert the track in the new position
    })

}

function reset() {
    var db = getPlaylistDatabase()

    db.transaction(function (tx) {
        tx.executeSql('DROP TABLE IF EXISTS playlist;')
        tx.executeSql('DROP TABLE IF EXISTS track;')
    })

    console.debug("Playlists deleted!")
}
