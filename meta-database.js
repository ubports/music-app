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

// First, let's create a short helper function to get the database connection
function getDatabase() {
     return LocalStorage.openDatabaseSync("music-app-metadata", "1.0", "StorageDatabase", 1000000);
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
        tx.executeSql("UPDATE recent SET data=?, WHERE type=? AND data=?",
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
