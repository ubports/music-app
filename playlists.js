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
     return LocalStorage.openDatabaseSync("music-app-playlist", "1.0", "StorageDatabase", 1000000);
}

// At the start of the application, we can initialize the tables we need if they haven't been created yet
function initializePlaylists() {
    var db = getPlaylistsDatabase();
    db.transaction(
        function(tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS playlists(id INTEGER, name TEXT)');
      });
}
// same thing for individal playlists
function initializePlaylist() {
    var db = getPlaylistDatabase();
    db.transaction(
        function(tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS playlist(playlist TEXT, track TEXT)');
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

   return res
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
function addtoPlaylist(playlist,track) {
    var db = getPlaylistDatabase();
    var res = "";
    db.transaction(function(tx) {
        var rs = tx.executeSql('INSERT OR REPLACE INTO playlist VALUES (?,?);', [playlist,track]);
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

// This function is used to retrieve a playlist from the database
function getPlaylist(playlistname) {
   var db = getPlaylistsDatabase();
   var res="";

   try {
       db.transaction(function(tx) {
         var rs = tx.executeSql('SELECT name FROM playlists WHERE name=?;', [playlistname]);
         if (rs.rows.length > 0) {
              res = rs.rows.item(0).value;
         } else {
             res = "Unknown";
         }
      })
   } catch(e) {
       return "";
   }

  return res
}

// retrieve tracks from playlist
function getPlaylistTracks(playlist) {
   var db = getPlaylistDatabase();
   var res="";

   try {
       db.transaction(function(tx) {
         var rs = tx.executeSql('SELECT * FROM playlist WHERE playlist=?;', [playlist]);
         if (rs.rows.length > 0) {
              res = rs.rows.item(0).value;
         } else {
             res = "Unknown";
         }
      })
   } catch(e) {
       return "";
   }

  return res
}

// be carefull, this will drop the playlists (db
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
