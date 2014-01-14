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

// Helper for the playlists database
function getPlaylistsDatabase() {
     return LocalStorage.openDatabaseSync("music-app-playlists", "1.0", "StorageDatabase", 1000000);
}

// database for individual playlists - the one witht the actual tracks in
function getPlaylistDatabase() {
     return LocalStorage.openDatabaseSync("music-app-playlist", "", "StorageDatabase", 1000000);
}

// At the start of the application, we can initialize the tables we need if they haven't been created yet
function initializePlaylists() {
    var db = getPlaylistsDatabase();
    db.transaction(
        function(tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS playlists(id INTEGER PRIMARY KEY, name TEXT)');
      });
}

// same thing for individal playlists
function initializePlaylist() {
    var db = getPlaylistDatabase();
    console.debug("Playlist DB is version "+db.version);

    // does the user have the latest db scheme?
    if (db.version === "1.0" || db.version === "1.1") {
        db.changeVersion(db.version,"1.2",function(t){
            t.executeSql('DROP TABLE IF EXISTS playlist'); // TODO: later, if we need a db version update, we should keep earlier settings. This is just for now.
            console.debug("DB: Changing version of playlist db to 1.2 by dropping it.")
        });
    }
    else {
        console.debug("DB: No change in playlist.")
    }

    db.transaction(
        function(tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS playlist(id INTEGER PRIMARY KEY, playlist TEXT, track TEXT, artist TEXT, title TEXT, album TEXT, cover TEXT, year TEXT, number TEXT, length TEXT, genre TEXT)');
      });
}

// we need an ID, so count the rows in db
function getID() {
    console.debug("Getting the latest ID of playlists.")
    var db = getPlaylistsDatabase();
    var res = 0;

    try {
        db.transaction(function(tx) {
            var rs = tx.executeSql('SELECT id FROM playlists ORDER BY id DESC LIMIT 1');
            for(var i = 0; i < rs.rows.length; i++) {
                var dbItem = rs.rows.item(i);
                console.debug("id of latest playlist: "+ dbItem.id);
                res = dbItem.id;
             }
       })
    } catch(e) {
        return -1;
    }

    console.debug("Print the return: "+res)
    return res;
}

// same thing when adding new tracks, we need the id
function getLatestTrackID(playlist) {
    var db = getPlaylistDatabase();
    var res = -1;

    try {
        db.transaction(function(tx) {
            // Get the maximum id for the playlist
            var rs = tx.executeSql('SELECT MAX(id) FROM playlist WHERE playlist=?;',[playlist]);

            // Set res to max id or -1 if no ids exist
            res = rs.rows.length === 0 ? -1 : rs.rows.item(0).id;
       })
    } catch(e) {
        return res;
    }

    console.debug("Print the return: "+res)
    return res;
}

// This function is used to write a playlist into the database
function addPlaylist(name) {
    var db = getPlaylistsDatabase();
    var res = "";
    var id = getID();
    var newid = id+1;

    console.debug("Debug: "+id);
    db.transaction(function(tx) {
        var rs = tx.executeSql('INSERT INTO playlists VALUES (?,?);', [newid,name]);
              if (rs.rowsAffected > 0) {
                res = "OK";
              } else {
                res = "Error";
              }
        }
  );
  // The function returns “OK” if it was successful, or “Error” if it wasn't
  return res;
}

// add track to playlist
function addtoPlaylist(playlist,track,artist,title,album,cover,year,number,length,genre) {
    var db = getPlaylistDatabase();
    var res = "";
    var newId = getLatestTrackID(playlist) + 1;

    db.transaction(
        function(tx) {
            var rs = tx.executeSql('INSERT OR REPLACE INTO playlist VALUES (?,?,?,?,?,?,?,?,?,?,?);', [newId,playlist,track,artist,title,album,cover,year,number,length,genre]);

            res = rs.rowsAffected > 0 ? "OK" : "Error";
        }
    );

    // The function returns “OK” if it was successful, or “Error” if it wasn't
    return res;
}

// This function is used to retrieve a playlist from the database in an array
function getPlaylists() {
   var db = getPlaylistsDatabase();
   var count = "";
   var res = new Array();
   var covers;

   try {
       db.transaction(function(tx) {
           var rs = tx.executeSql('SELECT * FROM playlists');
           for(var i = 0; i < rs.rows.length; i++) {
               var dbItem = rs.rows.item(i);
               count = getPlaylistCount(dbItem.name);

               covers = getRandomCovers(dbItem.name, 4)

               res[dbItem.id] = {
                   'id': dbItem.id,
                   'name': dbItem.name,
                   'count': count,
                   'cover0': covers[0],
                   'cover1': covers[1],
                   'cover2': covers[2],
                   'cover3': covers[3]
               }
            }
      })
   } catch(e) {
       return [];
   }
  return res
}

// retrieve tracks from playlist
function getPlaylistTracks(playlist) {
   var db = getPlaylistDatabase();
    var res = [];

   try {
       db.transaction(function(tx) {
         var rs = tx.executeSql('SELECT * FROM playlist WHERE playlist=?;', [playlist]);
         for(var i = 0; i < rs.rows.length; i++) {
             var dbItem = rs.rows.item(i);
             //console.log("Cover: "+ dbItem.cover);
             res[i] = {'file': dbItem.track,
                       'title': dbItem.title,
                       'artist': dbItem.artist,
                       'album': dbItem.album,
                       'cover': dbItem.cover,
                       'year': dbItem.year,
                       'number': dbItem.number,
                       'length': dbItem.length,
                       'genre': dbItem.genre,
                       'id': dbItem.id};
         }
      })
   } catch(e) {
       return [];
   }

   return res
}

// retrieve number of tracks in playlist
function getPlaylistCount(playlist) {
    console.debug("Trying to get count of "+playlist)
    var db = getPlaylistDatabase();
    var res = 0;

    try {
       db.transaction(function(tx) {
         var rs = tx.executeSql('SELECT * FROM playlist WHERE playlist=?;', [playlist]);
         res = rs.rows.length;
      })
    } catch(e) {
       return res;
    }

    console.debug("Playlist had: "+res)
    return res;
}

function getRandomCovers(playlist, max) {
    var db = getPlaylistDatabase();
    var res = [];

    // Get a list of unique covers for the playlist
    try {
        db.transaction(function(tx) {
            var rs = tx.executeSql('SELECT * FROM playlist WHERE playlist=?;', [playlist]);
            for(var i = 0; i < rs.rows.length; i++) {
                if (res.indexOf(rs.rows.item(i).cover) === -1) {
                    res.push(rs.rows.item(i).cover);
                }
            }
        })
    } catch(e) {
        return [];
    }

    // Randomly fill the array up to length of max with entries from the array
    while (res.length < max && res.length !== 0) {
        res.push(res[Math.floor(Math.random() * res.length)]);
    }

    return res;
}

// change name of playlist
function namechangePlaylist(old,nw) {
    // change the name in the playlists db
    var db = getPlaylistsDatabase();
    db.transaction(
        function(tx) {
            tx.executeSql('UPDATE playlists SET name=? WHERE name=?;',[nw, old]);
      });

    // change the name in the playlist db to make sure the tracks follow
    var db = getPlaylistDatabase();
    db.transaction(
        function(tx) {
            tx.executeSql('UPDATE playlist SET playlist=? WHERE playlist=?;',[nw, old] );
      });
}

// remove playlist
function removePlaylist(id,playlist) {
    var db = getPlaylistsDatabase();
    var res = "";
    db.transaction(
        function(tx) {
            var rs = tx.executeSql('DELETE FROM playlists WHERE id=? AND name=?;', [id,playlist]);

            if (rs.rowsAffected > 0)
            {
                res = "OK";
                reorder("playlists", id, playlist); // reorder the ids of playlists
            }
            else
            {
                res = "Error";
            }
        }
    );
  // The function returns “OK” if it was successful, or “Error” if it wasn't
  return res;
}

// remove file from playlist
function removeFromPlaylist(playlist, id) {
    var db = getPlaylistDatabase();
    var res = "";
    db.transaction(function(tx) {
        var rs = tx.executeSql('DELETE FROM playlist WHERE playlist=? AND id=?;', [playlist,id]);
              if (rs.rowsAffected > 0) {
                  res = "OK";
                  reorder("playlist", id, playlist); // reorder the ids
              } else {
                res = "Error";
              }
        }
  );

  // The function returns “OK” if it was successful, or “Error” if it wasn't
  return res;
}

// a reorder function for when tracks or playlists are removed
function reorder(database, removedid, playlist) {
    if (database === "playlist") {
        var db = getPlaylistDatabase();

        db.transaction(
            function(tx) {
                tx.executeSql("UPDATE playlist SET id=id -1 WHERE id > ? AND playlist=?;", [removedid,playlist])
            }
        );
    }
    else if (database === "playlists") {
        var db = getPlaylistsDatabase();

        db.transaction(
            function(tx) {
                tx.executeSql("UPDATE playlists SET id=id -1 WHERE id > ?;", [removedid])
            }
        );
    }
    else {
        console.debug("What was that? Issue in reordering.")
    }
}


// Get the real ID of an index in the playlist (-1 if doesn't exist/error)
function getRealID(playlist, index) {
    var db = getPlaylistDatabase();
    var realID = -1;

    try
    {
        db.transaction(
            function(tx)
            {
                var res = tx.executeSql("SELECT id FROM playlist WHERE playlist = ?;", [playlist]);
                realID = res.rows.item(index).id;
            }
        )
    }
    catch(e)
    {
        return realID;
    }

    return realID;
}


// Move an item in the playlist
function move(playlist, from, to)
{
    var db = getPlaylistDatabase();

    console.debug("Move", playlist, from, to);

    if (to > from)
    {
        db.transaction(
            function(tx) {
                tx.executeSql("UPDATE playlist SET id=-1 WHERE id=?;", [from]);
                tx.executeSql("UPDATE playlist SET id=id - 1 WHERE id > ? AND id <= ?;", [from, to]);
                tx.executeSql("UPDATE playlist SET id=? WHERE id=-1;", [to]);
            }
        );
    }
    else if (to < from)
    {
        db.transaction(
            function(tx) {
                tx.executeSql("UPDATE playlist SET id=-1 WHERE id=?;", [from]);

                for (var i=from - 1; i >= to; i--)
                {
                    tx.executeSql("UPDATE playlist SET id=id + 1 WHERE id=?;", [i]);
                }

                tx.executeSql("UPDATE playlist SET id=? WHERE id=-1;", [to]);
            }
        );
    }
}

// be carefull, this will drop the playlists (db)
function reset() {
    var db = getPlaylistsDatabase();
    db.transaction(
        function(tx) {
            tx.executeSql('DROP TABLE playlists');
      });
    var db = getPlaylistDatabase();
    db.transaction(
        function(tx) {
            tx.executeSql('DROP TABLE playlist');
      });
    console.debug("Playlists are gone. They're all gone...")
}
