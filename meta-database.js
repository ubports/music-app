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

// First, let's create a short helper function to get the database connection
function getDatabase() {
     return LocalStorage.openDatabaseSync("music-app-metadata", "1.0", "StorageDatabase", 1000000);
}

function createQueue(tx) {
    if (tx === undefined) {
        var db = getDatabase();
        db.transaction(
            function(tx) {
                createQueue(tx)
            }
        )
    } else {
        tx.executeSql("CREATE TABLE IF NOT EXISTS queue(ind INTEGER NOT NULL, filename TEXT)");
    }
}

function clearQueue() {
    var db = getDatabase();
    db.transaction(
        function(tx) {
            createQueue();
            tx.executeSql('DELETE FROM queue');
      });
}

function addQueueItem(filename) {
    var db = getDatabase();
    var res="";

    db.transaction(function(tx) {
        var ind = getNextIndex(tx);

        var rs = tx.executeSql('INSERT OR REPLACE INTO queue (ind, filename) VALUES (?,?);', [ind, filename]);
              if (rs.rowsAffected > 0) {
                console.log("QUEUE add OK")
                res = "OK";
              } else {
                console.log("QUEUE add Fail")
                res = "Error";
              }
        }
    );
}

function addQueueList(items) {
    var db = getDatabase();

    db.transaction(function(tx) {
        var ind = getNextIndex(tx);

        for (var i = 0; i < items.length; i++) {
            tx.executeSql('INSERT OR REPLACE INTO queue (ind, filename) VALUES (?,?);', [i + ind, items[i].filename]);
        }
    }
    );
}

// Get the next index for the queue
function getNextIndex(tx) {
    var ind;

    if (tx === undefined) {
        var db = getDatabase();

        db.transaction(function(tx) {
            ind = getNextIndex(tx);
        });
    } else {
        var rs = tx.executeSql('SELECT MAX(ind) FROM queue')
        ind = isQueueEmpty(tx) ? 0 : rs.rows.item(0)["MAX(ind)"] + 1
    }

    return ind;
}

function moveQueueItem(from, to) {
    var db = getDatabase();
    var res="";

    db.transaction(function(tx) {
        // Track to move put as -1 for now
        tx.executeSql('UPDATE queue SET ind=? WHERE ind=?;',
                      [-1, from])

        // Shuffle tracks inbetween from->to
        if (from > to) {
            for (var i = from-1; i >= to; i--) {
                tx.executeSql('UPDATE queue SET ind=? WHERE ind=?;',
                              [i+1, i])
            }
        } else {
            for (var j = from+1; j <= to; j++) {
                tx.executeSql('UPDATE queue SET ind=? WHERE ind=?;',
                              [j-1, j])
            }
        }

        // Switch moving track to its new position
        tx.executeSql('UPDATE queue SET ind=? WHERE ind=?;',
                      [to, -1])

    })
}

function removeQueueItem(ind) {
    var db = getDatabase()
    var res = false

    db.transaction(function (tx) {
        tx.executeSql('DELETE FROM queue WHERE ind=?;', [ind])

        var rs = tx.executeSql('SELECT MAX(ind) FROM queue')

        var lastIndex = isQueueEmpty() ? 0 : rs.rows.item(0)["MAX(ind)"]

        for(var i = ind+1; i <= lastIndex; i++) {
            tx.executeSql('UPDATE queue SET ind=? WHERE ind=?;',
                          [i-1, i])
        }
    })

    return res
}


// Optimised removeQueue for removing multiple tracks from the queue
function removeQueueList(list)
{
    var db = getDatabase()
    var i;
    var res = false

    db.transaction(function (tx) {
        // Remove all the deleted indexes
        for (i=0; i < list.length; i++) {
            tx.executeSql('DELETE FROM queue WHERE ind=?;', [list[i]])
        }

        // Rebuild queue in order
        var rs = tx.executeSql('SELECT ind FROM queue ORDER BY ind ASC')

        for (i=0; i < rs.rows.length; i++) {
            tx.executeSql('UPDATE queue SET ind=? WHERE ind=?;',
                          [i, rs.rows.item(i).ind])
        }
    })

    return res
}


function getQueue() {
    var res = [];
    var db = getDatabase();
    db.transaction( function(tx) {
        var rs = tx.executeSql("SELECT * FROM queue ORDER BY ind ASC");
        for(var i = 0; i < rs.rows.length; i++) {
            if (musicStore.lookup(rs.rows.item(i).filename) != undefined) {
                res.push(makeDict(musicStore.lookup(rs.rows.item(i).filename)));
            }
        }
    });
    return res;
}

function isQueueEmpty(tx) {
    var empty = false;

    if (tx === undefined) {
        var db = getDatabase();
        var res = 0;

        db.transaction( function(tx) {
            empty = isQueueEmpty(tx)
        });
    } else {
        createQueue(tx);
        var rs = tx.executeSql("SELECT count(*) as value FROM queue")
        empty = rs.rows.item(0).value === 0
    }

    return empty
}

function createRecent() {
    var db = getDatabase();
    db.transaction(
        function(tx) {
            // Data is either the playlist name or album name
            tx.executeSql("CREATE TABLE IF NOT EXISTS recent(time DATETIME UNIQUE, data TEXT, type TEXT)");

            // Check of old version of db and then clear if needed
            try {
                tx.executeSql("SELECT data FROM recent");
            } catch (e) {
                clearRecentHistory();
            }
      });
}

function clearRecentHistory() {
    var db = getDatabase();
    db.transaction(
        function(tx) {
            tx.executeSql('DROP TABLE IF EXISTS recent');
            tx.executeSql("CREATE TABLE IF NOT EXISTS recent(time DATETIME UNIQUE, data TEXT, type TEXT)");
      });
}


// This function is used to insert a recent item into the database
function addRecent(data, type) {
    var db = getDatabase();

    console.debug("RECENT", data, type);


    db.transaction(function (tx) {
        // Remove old albums/playlists with same name as they have a new time
        if (type === "album") {
            tx.executeSql("DELETE FROM recent WHERE type=? AND data=?", ["album", data])
        } else if (type === "playlist") {
            tx.executeSql("DELETE FROM recent WHERE type=? AND data=?", ["playlist", data])
        }

        var rs = tx.executeSql('INSERT OR REPLACE INTO recent (time, data, type) VALUES (?, ?, ?)', [new Date(), data, type]);

        if (rs.rowsAffected <= 0) {
            console.debug("RECENT add Fail")
        }
    });
}

function getRecent() {
    var res = [];
    var db = getDatabase();

    db.transaction( function(tx) {
        var rs = tx.executeSql("SELECT * FROM recent ORDER BY time DESC LIMIT 15");
        for(var i = 0; i < rs.rows.length; i++) {
            var dbItem = rs.rows.item(i);

            console.log("Time:", dbItem.time, ", Data:", dbItem.data, ", Type:", dbItem.type);

            res.push({"time": dbItem.time, "data": dbItem.data, "type": dbItem.type});
        }
    });
    return res;
}

function recentContainsPlaylist(key) {
    var db = getDatabase();
    var rs;

    db.transaction(function(tx) {
        rs = tx.executeSql("SELECT count(*) as value FROM recent WHERE type=? AND data=?",
                           ["playlist", key]);
    });

    return rs.rows.item(0).value > 0;
}

function recentRemovePlaylist(key) {
    var res = false
    var db = getDatabase();

    db.transaction( function(tx) {
        res = tx.executeSql("DELETE FROM recent WHERE type=? AND data=?",
                            ["playlist", key]).rowsAffected > 0;

    })

    return res;
}

function recentRenamePlaylist(oldKey, newKey) {
    var db = getDatabase();

    db.transaction( function(tx) {
        tx.executeSql("UPDATE recent SET data=? WHERE type=? AND data=?",
                      [newKey, "playlist", oldKey]);

    });
}

function isRecentEmpty() {
    var db = getDatabase();
    var res = 0;

    db.transaction(function(tx) {
        var rs = tx.executeSql("SELECT count(*) as value FROM recent")

        if (rs.rows.item(0).value > 0) {
            res = rs.rows.item(0).value;
        } else {
            console.log("RECENT does not exist")
            res = 0;
        }
    });

    return res === 0;
}
