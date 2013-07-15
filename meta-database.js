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

var buffer = [];  // Buffer of metadata to write to the db
var maxBufferLength = 5000;  // Maximum size of buffer before auto write to db

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
            //tx.executeSql('DROP TABLE metadata');
            tx.executeSql('CREATE TABLE IF NOT EXISTS metadata(file TEXT UNIQUE, title TEXT, artist TEXT, album TEXT, cover TEXT, year TEXT, number TEXT, length TEXT)');
      });
}
function reset() {
    var db = getDatabase();
    db.transaction(
        function(tx) {
            // Create the table if it doesn't already exist
            // If the table exists, this is skipped
            tx.executeSql('DROP TABLE metadata');
            tx.executeSql('CREATE TABLE IF NOT EXISTS metadata(file TEXT UNIQUE, title TEXT, artist TEXT, album TEXT, cover TEXT, year TEXT, number TEXT, length TEXT)');
            //tx.executeSql('CREATE TABLE IF NOT EXISTS metadata(file TEXT UNIQUE, title TEXT, artist TEXT, album TEXT, cover TEXT, year TEXT, number TEXT, length TEXT)');
      });
}

// This function is used to flush the buffer of metadata to the db
function writeDb()
{
    var db = getDatabase();
    var res = "";
    var i;

    console.debug("Writing DB");
    console.debug(buffer.length);

    // Keep within one transaction for performance win
    db.transaction(function(tx) {
        // Loop through all the metadata in the buffer
        for (i=0; i < buffer.length; i++)
        {
            var res = tx.executeSql('INSERT OR REPLACE INTO metadata VALUES (?,?,?,?,?,?,?,?);', buffer[i]);

            if (res.rowsAffected <= 0)
            {
                // Nothing was added error occured?
                console.debug("Error occured writing to db for ", buffer[i]);
            }
        }
    });

    buffer = [];  // Clear buffer
}

// This function is used to write meta data into the database
function setMetadata(file, title, artist, album, cover, year, number, length) {
    buffer.push([file,title,artist,album,cover,year,number,length]);  // Add metadata to buffer

    if (buffer.length >= maxBufferLength)
    {
        console.debug("Buffer full, flushing buffer to disk");
        writeDb();
    }
}

// This function is used to retrieve meta data from the database
function getMetadata(file,type) {
   var db = getDatabase();
   var res="";

   try {
       db.transaction(function(tx) {
         //var rs = tx.executeSql('SELECT type=?;',[type],' FROM metadata WHERE file=?;', [file]); // tries to get the title of track
         var rs = tx.executeSql('SELECT ? FROM metadata WHERE file=?;', [type,file]); // tries to get the title of track

         if (rs.rows.length > 0) {
              res = rs.rows.item(0).value;
         } else {
             res = "Unknown";
         }
      })
   } catch(e) {
       return "";
   }

  // The function returns “Unknown” if the setting was not found in the database
  // For more advanced projects, this should probably be handled through error codes
  return res
}

function printValues() {
    var db = getDatabase();
    db.transaction( function(tx) {
        var rs = tx.executeSql("SELECT * FROM metadata");
        for(var i = 0; i < rs.rows.length; i++) {
            var dbItem = rs.rows.item(i);
            console.log("Artist:"+ dbItem.artist + ", Album:"+dbItem.album + ", Title:"+dbItem.title + ", File:"+dbItem.file + ", Art:"+dbItem.cover);
        }
    });
}


function getAll() {
    var res = [];
    var db = getDatabase();
    db.transaction( function(tx) {
        var rs = tx.executeSql("SELECT * FROM metadata");
        for(var i = rs.rows.length - 1; i >= 0; i--) {
            var dbItem = rs.rows.item(i);
            console.log("Artist:"+ dbItem.artist + ", Album:"+dbItem.album + ", Title:"+dbItem.title + ", File:"+dbItem.file + ", Art:"+dbItem.cover);
            res.push({artist:dbItem.artist, album:dbItem.album, title:dbItem.title, file:dbItem.file, cover:dbItem.cover, length:dbItem.length});
        }
    });
    return res;
}

function getArtists() {
    var res = [];
    var db = getDatabase();
    db.transaction( function(tx) {
        var rs = tx.executeSql("SELECT DISTINCT artist FROM metadata");
        for(var i = 0; i < rs.rows.length; i++) {
            var dbItem = rs.rows.item(i);
            console.log("Artist:"+ dbItem.artist + ", Album:"+dbItem.album + ", Title:"+dbItem.title + ", File:"+dbItem.file + ", Art:"+dbItem.cover);
            res.push({artist:dbItem.artist, album:dbItem.album, title:dbItem.title, file:dbItem.file, cover:dbItem.cover, length:dbItem.length});
        }
    });
    return res;
}

function getAlbums() {
    var res = [];
    var db = getDatabase();
    db.transaction( function(tx) {
        var rs = tx.executeSql("SELECT DISTINCT album FROM metadata");
        for(var i = 0; i < rs.rows.length; i++) {
            var dbItem = rs.rows.item(i);
            console.log("Artist:"+ dbItem.artist + ", Album:"+dbItem.album + ", Title:"+dbItem.title + ", File:"+dbItem.file + ", Art:"+dbItem.cover);
            res.push({artist:dbItem.artist, album:dbItem.album, title:dbItem.title, file:dbItem.file, cover:dbItem.cover, length:dbItem.length});
        }
    });
    return res;
}


function size() {
    var db = getDatabase();
    var res="";

    db.transaction( function(tx) {
        var rs = tx.executeSql("SELECT count(*) FROM metadata");
        res = rs.rows.item(0).value;
    });
    return res;
}
