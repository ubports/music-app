// meta-database.js
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
            tx.executeSql('CREATE TABLE IF NOT EXISTS metadata(file TEXT UNIQUE, title TEXT, artist TEXT, album TEXT, year TEXT, tracknr TEXT, length TEXT)');
      });
}

// This function is used to write a setting into the database
function setSetting(file, title, artist, album, year, tracknr, length) {
    var db = getDatabase();
    var res = "";
    db.transaction(function(tx) {
        var rs = tx.executeSql('INSERT OR REPLACE INTO metadata VALUES (?,?);', [file,title,artist,album,year,tracknr,length]);
              //console.log(rs.rowsAffected)
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
// This function is used to retrieve a setting from the database
function getSetting(file) {
   var db = getDatabase();
   var res="";

   try {
       db.transaction(function(tx) {
         var rs = tx.executeSql('SELECT title FROM metadata WHERE file=?;', [file]); // tries to get the title of track
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
