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
      });
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
            console.log("Time:"+ dbItem.time + ", Key:"+dbItem.key + ", Title:"+dbItem.title + ", Title2:"+dbItem.title2 + ", Type:"+dbItem.type);

            if (dbItem.type === "album")
            {
                res.push({time:dbItem.time,
                             title:dbItem.title || i18n.tr("Unknown Album"),
                             title2:dbItem.title2 || i18n.tr("Unknown Artist"),
                             key:dbItem.key || i18n.tr("Unknown Album"),
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
