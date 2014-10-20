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

// At the start of the application, we can initialize the tables we need if they haven't been created yet
function initialize() {
    var db = getDatabase();
    db.transaction(
        function(tx) {
            // Create the table if it doesn't already exist
            // If the table exists, this is skipped
            tx.executeSql('DROP TABLE IF EXISTS metadata');  // TODO: drop recent as well to reset data

            createRecent();
            createQueue();
      });
}

function createQueue() {
    var db = getDatabase();
    db.transaction(
        function(tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS queue(ind INTEGER NOT NULL, album TEXT, art TEXT, author TEXT, filename TEXT, title TEXT)");
      });
}

function clearQueue() {
    var db = getDatabase();
    db.transaction(
        function(tx) {
            tx.executeSql('DROP TABLE IF EXISTS queue');
            tx.executeSql("CREATE TABLE IF NOT EXISTS queue(ind INTEGER NOT NULL, album TEXT, art TEXT, author TEXT, filename TEXT, title TEXT)");
      });
}

function addQueueItem(ind, album, art, author, filename, title) {
    var db = getDatabase();
    var res="";

    db.transaction(function(tx) {
        var rs = tx.executeSql('INSERT OR REPLACE INTO queue (ind, album, art, author, filename, title) VALUES (?,?,?,?,?,?);', [ind, album, art, author, filename, title]);
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

function addQueueList(model) {
    var db = getDatabase();
    var res="";

    db.transaction(function(tx) {

        for (var i = 0; i < model.count; i++) {
            var rs = tx.executeSql('INSERT OR REPLACE INTO queue (ind, album, art, author, filename, title) VALUES (?,?,?,?,?,?);', [i, model.get(i).album, model.get(i).art, model.get(i).author, model.get(i).filename, model.get(i).title]);
            if (rs.rowsAffected > 0) {
                res = "OK";
            } else {
                res = "Error";
            }
        }
    }
    );
}

function moveQueueItem(from, to) {
    var db = getDatabase();
    var res="";

    db.transaction(function(tx) {

        // Generate new index number if records exist, otherwise use 0
        var rs = tx.executeSql('SELECT MAX(ind) FROM queue')

        var nextIndex = isNaN(rs.rows.item(0)["MAX(ind)"]) ? 0 : rs.rows.item(
                                                                   0)["MAX(ind)"] + 1

        tx.executeSql('UPDATE queue SET ind=? WHERE ind=?;',
                      [nextIndex, from])

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

        tx.executeSql('UPDATE queue SET ind=? WHERE ind=?;',
                      [to, nextIndex])

    })
}

function removeQueueItem(ind) {
    var db = getDatabase()
    var res = false

    db.transaction(function (tx) {
        tx.executeSql('DELETE FROM queue WHERE ind=?;', [ind])

        var rs = tx.executeSql('SELECT MAX(ind) FROM queue')

        var lastIndex = isNaN(rs.rows.item(0)["MAX(ind)"]) ? 0 : rs.rows.item(
                                                           0)["MAX(ind)"]
        for(var i = ind+1; i <= lastIndex; i++) {
            tx.executeSql('UPDATE queue SET ind=? WHERE ind=?;',
                          [i-1, i])
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
            var dbItem = rs.rows.item(i);
            res.push({album:dbItem.album,
                         art:dbItem.art,
                         author:dbItem.author,
                         filename:dbItem.filename,
                         title:dbItem.title
                     });
        }
    });
    return res;
}

function isQueueEmpty() {
    var db = getDatabase();
    var res = 0;

    db.transaction( function(tx) {
        createRecent();
        var rs = tx.executeSql("SELECT count(*) as value FROM queue")
        res = rs.rows.item(0).value === 0
    });
    return res
}

function createRecent() {
    var db = getDatabase();
    db.transaction(
        function(tx) {
            // "key" is the search criteria for the type.
            // album title for album, and playlist title for playlist
            //tx.executeSql('DROP TABLE recent');
            tx.executeSql("CREATE TABLE IF NOT EXISTS recent(time DATETIME, title TEXT, title2 TEXT, cover TEXT, key TEXT UNIQUE, type TEXT)");
      });
}

function clearRecentHistory() {
    var db = getDatabase();
    db.transaction(
        function(tx) {
            tx.executeSql('DROP TABLE IF EXISTS recent');
            tx.executeSql("CREATE TABLE IF NOT EXISTS recent(time DATETIME, title TEXT, title2 TEXT, cover TEXT, key TEXT UNIQUE, type TEXT)");
      });
}

// This function is used to insert a recent item into the database
function addRecent(title, title2, cover, key, type) {
    var db = getDatabase();
    var res="";

    console.log("RECENT " + key + title + title2 + cover)

    db.transaction(function(tx) {
        var rs = tx.executeSql('INSERT OR REPLACE INTO recent (time, title, title2, cover, key, type) VALUES (?,?,?,?,?,?);', [new Date(), title, title2, cover, key, type]);
              if (rs.rowsAffected > 0) {
                console.log("RECENT add OK")
                res = "OK";
              } else {
                console.log("RECENT add Fail")
                res = "Error";
              }
        }
    );
}

function getRecent() {
    var res = [];
    var db = getDatabase();
    db.transaction( function(tx) {
        var rs = tx.executeSql("SELECT * FROM recent ORDER BY time DESC LIMIT 15");
        for(var i = 0; i < rs.rows.length; i++) {
            var dbItem = rs.rows.item(i);
            console.log("Time:"+ dbItem.time + ", Key:"+dbItem.key + ", Title:"+dbItem.title + ", Title2:"+dbItem.title2 + ", Type:"+dbItem.type + ", Art:"+dbItem.cover);

            if (dbItem.type === "album")
            {
                res.push({time:dbItem.time,
                             title:dbItem.title || i18n.tr("Unknown Album"),
                             title2:dbItem.title2 || i18n.tr("Unknown Artist"),
                             key:dbItem.key || i18n.tr("Unknown Album"),
                             art:dbItem.cover || undefined,
                             type:dbItem.type
                         });
            }
            else
            {
                res.push({time:dbItem.time, title:dbItem.title, title2:dbItem.title2, key:dbItem.key, type:dbItem.type});
            }
        }
    });
    return res;
}

function isRecentEmpty() {
    var db = getDatabase();
    var res = 0;

    db.transaction( function(tx) {
        createRecent();
        var rs = tx.executeSql("SELECT count(*) as value FROM recent")
        if (rs.rows.item(0).value > 0) {
            res = rs.rows.item(0).value;
        } else {
            console.log("RECENT does not exist")
            res = 0;
        }
    }
    );
    return res === 0;
}
