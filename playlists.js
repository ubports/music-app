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
     return LocalStorage.openDatabaseSync("music-app-playlist", "1.1", "StorageDatabase", 1000000);
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
    var db = LocalStorage.openDatabaseSync("music-app-playlist", "", "StorageDatabase", 1000000);

    // does the user have the latest db scheme?
    if (db.version === "1.0") {
        db.changeVersion("1.0","1.1",function(t){
            t.executeSql('DROP TABLE playlist'); // TODO: later, if we need a db version update, we should keep earlier settings. This is just for now.
            console.debug("DB: Changing version of playlist db to 1.1.")
        });
    }
    else {
        console.debug("DB: No change in playlist.")
    }

    db.transaction(
        function(tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS playlist(playlist TEXT, track TEXT, artist TEXT, title TEXT, album TEXT)');
      });
}

// we need an ID, so count the rows in db
function getID() {
    var db = getPlaylistsDatabase();
    var res = "";
    try {
        db.transaction(function(tx) {
          var rs = tx.executeSql('SELECT * FROM playlists');
          if (rs.rows.length > 0) {
              res = rs.rows.length;
          } else {
              res = 0;
          }
       })
    } catch(e) {
        return "";
    }
   return res;
}

// This function is used to write a playlist into the database
function addPlaylist(name) {
    var db = getPlaylistsDatabase();
    var res = "";
    var id = getID();
    if (id === 0) {
        var newid = 0;
    }
    else {
        var newid = id+1;
    }

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
function addtoPlaylist(playlist,track,artist,title,album) {
    var db = getPlaylistDatabase();
    var res = "";
    db.transaction(function(tx) {
        var rs = tx.executeSql('INSERT OR REPLACE INTO playlist VALUES (?,?,?,?,?);', [playlist,track,artist,title,album]);
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

// This function is used to retrieve a playlist from the database in an array
function getPlaylists() {
   var db = getPlaylistsDatabase();
   var res = new Array();

   try {
       db.transaction(function(tx) {
           var rs = tx.executeSql('SELECT * FROM playlists');
           for(var i = 0; i < rs.rows.length; i++) {
               var dbItem = rs.rows.item(i);
               //console.log("id:"+ dbItem.id + ", Name:"+dbItem.name);
               res[i] = dbItem.name;
           }
      })
   } catch(e) {
       return "";
   }
  return res
}

// retrieve tracks from playlist
function getPlaylistTracks(playlist) {
   console.log("I got "+playlist)
   var db = getPlaylistDatabase();
   var res = new Array();

   try {
       db.transaction(function(tx) {
         var rs = tx.executeSql('SELECT * FROM playlist WHERE playlist=?;', [playlist]);
         for(var i = 0; i < rs.rows.length; i++) {
             var dbItem = rs.rows.item(i);
             console.log("Track: "+ dbItem.track);
             console.log("Artist: "+ dbItem.artist);
             console.log("Title: "+ dbItem.title);
             console.log("Album: "+ dbItem.album);
             res[i] = {'file': dbItem.track,
                       'title': dbItem.title,
                       'artist': dbItem.artist,
                       'album': dbItem.album,
                       'index': i};
         }
      })
   } catch(e) {
       return [];
   }

   return res
}

// change name of playlist
function namechangePlaylist(old,nw) {
    // change the name in the playlists db
    var db = getPlaylistsDatabase();
    db.transaction(
        function(tx) {
            tx.executeSql('UPDATE playlists SET name=? WHERE name=?;',[nw,old]);
      });

    // change the name in the playlist db to make sure the tracks follow
    var db = getPlaylistDatabase();
    db.transaction(
        function(tx) {
            tx.executeSql('UPDATE playlist SET playlist=? WHERE playlist=?;', [ nw, old] );
      });
}

// remove playlist
function removePlaylist(id,playlist) {
    var db = getPlaylistsDatabase();
    var res = "";
    db.transaction(function(tx) {
        var rs = tx.executeSql('DELETE FROM playlists WHERE id=? AND name=?;', [id,playlist]);
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
}
