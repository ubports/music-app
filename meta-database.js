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
var maxBufferLength = 8000;  // Maximum size of buffer before auto write to db

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
            tx.executeSql('CREATE TABLE IF NOT EXISTS metadata(file TEXT UNIQUE, title TEXT, artist TEXT, album TEXT, cover TEXT, year TEXT, number TEXT, length TEXT, genre TEXT)');
            createRecent();
      });
}
function reset() {
    var db = getDatabase();
    db.transaction(
        function(tx) {
            // Create the table if it doesn't already exist
            // If the table exists, this is skipped
            tx.executeSql('DROP TABLE IF EXISTS metadata');
            tx.executeSql('CREATE TABLE IF NOT EXISTS metadata(file TEXT UNIQUE, title TEXT, artist TEXT, album TEXT, cover TEXT, year TEXT, number TEXT, length TEXT, genre TEXT)');
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
            var res = tx.executeSql('INSERT OR REPLACE INTO metadata VALUES (?,?,?,?,?,?,?,?,?);', buffer[i]);

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
function setMetadata(record) {
    buffer.push([record.file,record.title,record.artist,record.album,record.cover,record.year,record.number,record.length,record.genre]);  // Add metadata to buffer

    if (buffer.length >= maxBufferLength)
    {
        console.debug("Buffer full, flushing buffer to disk");
        writeDb();
    }
}


function removeFiles(files)
{
    var db = getDatabase();

    db.transaction(function(tx) {
        for (var i=0; i < files.length; i++)
        {
            for (var k in files[i])
            {
                tx.executeSql('DELETE FROM metadata WHERE file=?;', files[i]["file"]);
            }
        }
    });
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

// This function is used to retrieve meta data from the database
function hasCover(file) {
   var db = getDatabase();
   var res = false;

   try {
       db.transaction(function(tx) {
         var rs = tx.executeSql('SELECT cover FROM metadata WHERE file = ?;', [file]); // tries to get the cover art of track

         if (rs.rows.length > 0) {
              res = rs.rows.item(0).cover !== ""
         }
      })
   } catch(e) {
       return false;
   }

  // The function returns false if cover art was not found in the database
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
        var rs = tx.executeSql("SELECT * FROM metadata ORDER BY title COLLATE NOCASE ASC, artist COLLATE NOCASE ASC, album COLLATE NOCASE ASC, CAST(number AS int) ASC");
        for(var i = 0; i < rs.rows.length; i++) {
            var dbItem = rs.rows.item(i);
            //console.log("Artist:"+ dbItem.artist + ", Album:"+dbItem.album + ", Title:"+dbItem.title + ", File:"+dbItem.file + ", Art:"+dbItem.cover + ", Genre:"+dbItem.genre);
            res.push({artist:dbItem.artist, album:dbItem.album, title:dbItem.title, file:dbItem.file, cover:dbItem.cover, length:dbItem.length, year:dbItem.year, genre:dbItem.genre});
        }
    });
    return res;
}

function getAllFileOrder() {
    var res = [];
    var db = getDatabase();
    db.transaction( function(tx) {
        var rs = tx.executeSql("SELECT * FROM metadata ORDER BY file COLLATE NOCASE ASC");
        for(var i = 0; i < rs.rows.length; i++) {
            var dbItem = rs.rows.item(i);
            //console.log("Artist:"+ dbItem.artist + ", Album:"+dbItem.album + ", Title:"+dbItem.title + ", File:"+dbItem.file + ", Art:"+dbItem.cover + ", Genre:"+dbItem.genre);
            res.push({artist:dbItem.artist, album:dbItem.album, title:dbItem.title, file:dbItem.file, cover:dbItem.cover, length:dbItem.length, number:dbItem.number, year:dbItem.year, genre:dbItem.genre});
        }
    });
    return res;
}

function getArtists() {
    var res = [];
    var db = getDatabase();
    db.transaction( function(tx) {
        var rs = tx.executeSql("SELECT * FROM metadata GROUP BY artist ORDER BY artist COLLATE NOCASE ASC");
        for(var i = 0; i < rs.rows.length; i++) {
            var dbItem = rs.rows.item(i);
            //console.log("Artist:"+ dbItem.artist + ", Album:"+dbItem.album + ", Title:"+dbItem.title + ", File:"+dbItem.file + ", Art:"+dbItem.cover + ", Genre:"+dbItem.genre);
            res.push({artist:dbItem.artist, album:dbItem.album, title:dbItem.title, file:dbItem.file, cover:dbItem.cover, length:dbItem.length, year:dbItem.year, genre:dbItem.genre});
        }
    });
    return res;
}

function getArtistTracks(artist) {
    var res = [];
    var db = getDatabase();
    db.transaction( function(tx) {
        var rs = tx.executeSql("SELECT * FROM metadata WHERE artist=? ORDER BY artist COLLATE NOCASE ASC, album COLLATE NOCASE ASC, CAST(number AS int) ASC", [artist]);
        for(var i = 0; i < rs.rows.length; i++) {
            var dbItem = rs.rows.item(i);
            //console.log("Artist:"+ dbItem.artist + ", Album:"+dbItem.album + ", Title:"+dbItem.title + ", File:"+dbItem.file + ", Art:"+dbItem.cover + ", Genre:"+dbItem.genre);
            res.push({artist:dbItem.artist, album:dbItem.album, title:dbItem.title, file:dbItem.file, cover:dbItem.cover, length:dbItem.length, year:dbItem.year, genre:dbItem.genre});
        }
    });
    return res;
}

function getArtistAlbums(artist) {
    var res = [];
    var db = getDatabase();
    db.transaction( function(tx) {
        var rs = tx.executeSql("SELECT * FROM metadata WHERE artist=? GROUP BY album ORDER BY year ASC, CAST(number AS int) ASC", [artist]);
        for(var i = 0; i < rs.rows.length; i++) {
            var dbItem = rs.rows.item(i);
            //console.log("Artist:"+ dbItem.artist + ", Album:"+dbItem.album + ", Title:"+dbItem.title + ", File:"+dbItem.file + ", Art:"+dbItem.cover + ", Genre:"+dbItem.genre);
            res.push({artist:dbItem.artist, album:dbItem.album, title:dbItem.title, file:dbItem.file, cover:dbItem.cover, length:dbItem.length, year:dbItem.year, genre:dbItem.genre});
        }
    });
    return res;
}

function getArtistCovers(artist) {
    var res = [];
    var db = getDatabase();
    try {
        db.transaction( function(tx) {
            var rs = tx.executeSql("SELECT cover FROM metadata WHERE artist=? AND cover <> '' ORDER BY album COLLATE NOCASE ASC", [artist]);
            for(var i = 0; i < rs.rows.length; i++) {
                var dbItem = rs.rows.item(i);
                //console.log("Cover:"+ dbItem.cover+" Size:"+res.length);
                if (res.indexOf(dbItem.cover) == -1) res.push(dbItem.cover);
            }
        });
    } catch(e) {
        return [];
    }

    return res;
}

function getAlbumCover(album) {
    var res = "";
    var db = getDatabase();
    try {
        db.transaction( function(tx) {
            var rs = tx.executeSql("SELECT cover FROM metadata WHERE album=? ORDER BY cover DESC", [album]);
            var dbItem = rs.rows.item(0);
            //console.log("Cover:"+ dbItem.cover+" Size:"+res.length);
            if (res.indexOf(dbItem.cover) == -1) res = dbItem.cover;
        });
    } catch(e) {
        return [];
    }

    return res;
}

function getArtistAlbumCount(artist) {
    var res = 0;
    var db = getDatabase();
    db.transaction( function(tx) {
        var rs = tx.executeSql("SELECT count(DISTINCT album) AS value FROM metadata WHERE artist=?", [artist]);
        if (rs.rows.item(0).value > 0) {
            res = rs.rows.item(0).value;
        } else {
            res = 0;
        }
    });
    return res;
}

function getAlbums() {
    var res = [];
    var db = getDatabase();
    try {
        db.transaction( function(tx) {
            var rs = tx.executeSql("SELECT * FROM metadata GROUP BY album ORDER BY album COLLATE NOCASE ASC");
            for(var i = 0; i < rs.rows.length; i++) {
                var dbItem = rs.rows.item(i);
                //console.log("Artist:"+ dbItem.artist + ", Album:"+dbItem.album + ", Title:"+dbItem.title + ", File:"+dbItem.file + ", Art:"+dbItem.cover + ", Genre:"+dbItem.genre);
                res.push({artist:dbItem.artist, album:dbItem.album, title:dbItem.title, file:dbItem.file, cover:dbItem.cover, length:dbItem.length, year:dbItem.year, genre:dbItem.genre});
            }
        });
    } catch(e) {
        return [];
    }

    return res;
}

function getAlbumTracks(album) {
    var res = [];
    var db = getDatabase();
    //console.log("Album: " + album);
    db.transaction( function(tx) {
        var rs = tx.executeSql("SELECT * FROM metadata WHERE album=? ORDER BY artist COLLATE NOCASE ASC, album COLLATE NOCASE ASC, CAST(number AS int) ASC", [album]);
        for(var i = 0; i < rs.rows.length; i++) {
            var dbItem = rs.rows.item(i);
            //console.log("Artist:"+ dbItem.artist + ", Album:"+dbItem.album + ", Title:"+dbItem.title + ", File:"+dbItem.file + ", Art:"+dbItem.cover + ", Genre:"+dbItem.genre);
            res.push({artist:dbItem.artist, album:dbItem.album, title:dbItem.title, file:dbItem.file, cover:dbItem.cover, length:dbItem.length, year:dbItem.year, genre:dbItem.genre});
        }
    });
    return res;
}

function getGenres() {
    var res = [];
    var db = getDatabase();
    db.transaction( function(tx) {
        var rs = tx.executeSql("SELECT *, count(genre) AS total FROM metadata GROUP BY genre ORDER BY genre COLLATE NOCASE ASC");
        for(var i = 0; i < rs.rows.length; i++) {
            var dbItem = rs.rows.item(i);
            //console.log("Artist:"+ dbItem.artist + ", Album:"+dbItem.album + ", Title:"+dbItem.title + ", File:"+dbItem.file + ", Art:"+dbItem.cover + ", Genre:"+dbItem.genre);
            res.push({artist:dbItem.artist, album:dbItem.album, title:dbItem.title, file:dbItem.file, cover:dbItem.cover, length:dbItem.length, year:dbItem.year, genre:dbItem.genre, total: dbItem.total});
        }
    });
    return res;
}

function getGenreTracks(genre) {
    var res = [];
    var db = getDatabase();
    //console.log("Genre: " + genre);
    db.transaction( function(tx) {
        var rs = tx.executeSql("SELECT * FROM metadata WHERE genre=? ORDER BY artist COLLATE NOCASE ASC, album COLLATE NOCASE ASC, CAST(number AS int) ASC", [genre]);
        for(var i = 0; i < rs.rows.length; i++) {
            var dbItem = rs.rows.item(i);
            //console.log("Artist:"+ dbItem.artist + ", Album:"+dbItem.album + ", Title:"+dbItem.title + ", File:"+dbItem.file + ", Art:"+dbItem.cover + ", Genre:"+dbItem.genre);
            res.push({artist:dbItem.artist, album:dbItem.album, title:dbItem.title, file:dbItem.file, cover:dbItem.cover, length:dbItem.length, year:dbItem.year, genre:dbItem.genre});
        }
    });
    return res;
}

function getGenreCovers(genre) {
    var res = [];
    var db = getDatabase();
    try {
        db.transaction( function(tx) {
            var rs = tx.executeSql("SELECT cover FROM metadata WHERE genre=? AND cover <> '' ORDER BY artist COLLATE NOCASE ASC", [genre]);
            for(var i = 0; i < rs.rows.length; i++) {
                if (res.indexOf(rs.rows.item(i).cover) === -1) {
                    res.push(rs.rows.item(i).cover);
                }
            }
        });
    } catch(e) {
        return [];
    }

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
            console.log("Time:"+ dbItem.time + ", Key:"+dbItem.key + ", Title:"+dbItem.title + ", Title2:"+dbItem.title2 + ", Cover:"+dbItem.cover + ", Type:"+dbItem.type);

            if (dbItem.type === "album")
            {
                res.push({time:dbItem.time,
                             title:dbItem.title || i18n.tr("Unknown Album"),
                             title2:dbItem.title2 || i18n.tr("Unknown Artist"),
                             cover:dbItem.cover,
                             key:dbItem.key || i18n.tr("Unknown Album"),
                             type:dbItem.type
                         });
            }
            else
            {
                res.push({time:dbItem.time, title:dbItem.title, title2:dbItem.title2, cover:dbItem.cover, key:dbItem.key, type:dbItem.type});
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

// Search track LIKE
function search(input) {
    console.debug("Got a new search: "+input)
    input = "%" + input + "%" // workaround
    var res = [];
    var db = getDatabase();
    db.transaction( function(tx) {
        var rs = tx.executeSql("SELECT * FROM metadata WHERE title LIKE ? OR artist LIKE ? OR album LIKE ? OR genre LIKE ?;", [input,input,input,input]); // WRONG! WHy?
        for(var i = 0; i < rs.rows.length; i++) {
            var dbItem = rs.rows.item(i);
            console.log("Artist:"+ dbItem.artist + ", Album:"+dbItem.album + ", Title:"+dbItem.title + ", File:"+dbItem.file + ", Art:"+dbItem.cover + ", Genre:"+dbItem.genre);
            res.push({artist:dbItem.artist, album:dbItem.album, title:dbItem.title, file:dbItem.file, cover:dbItem.cover, length:dbItem.length, year:dbItem.year, genre:dbItem.genre});
        }
    });
    return res;
}
