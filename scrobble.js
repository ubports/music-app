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

// VARIABLES
var api_key = "07c14de06e622165b5b4d55deb85f4da"
var secret_key = "14125657da06bcb14919e23e2f09de32"
var scrobble_url = "http://ws.audioscrobbler.com/2.0/"
var session_key = ""

// FUNCTIONS
// get settings database (later, use settings.js and meta-database.js
function getDatabase() {
     return LocalStorage.openDatabaseSync("music-app-metadata", "1.0", "StorageDatabase", 1000000);
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

// get playlist of user
function getPlaylists(username) {
    var getPlaylistsURL = scrobble_url+"?method=user.getplaylists&user="+username+"&api_key="+api_key
    console.debug("Debug: url of call: "+getPlaylistsURL)

    // send request
    // not ready yetrequest(getPlaylistsURL)
}

// scrobble track
function scrobble(track,timestamp) {
    var artist = getMetadata(track,artist)
    var title = getMetadata(track,title)
    var scrobbleURL = scrobble_url+"?method=track.scrobble&artist[0]="+artist+"&track[0]="+title+"&timestamp="+timestamp+"&api_key="+api_key+"&api_sig="+secret_key+"&sk="+session_key
    console.debug("Debug: Scrobble "+title+" "+artist+" "+timestamp)
    // login first
    //authenticate(username,password)
    // send request
    // not ready yetrequest(scrobbleURL) // send the request
}

function now_playing(track,timestamp) {
    var artist = getMetadata(track,artist)
    var title = getMetadata(track,title)
    var nowPlayingURL = scrobble_url+"?method=track.updateNowPlaying&artist[0]="+artist+"&track[0]="+title+"&timestamp="+timestamp+"&api_key="+api_key+"&api_sig="+secret_key+"&sk="+session_key
    console.debug("Debug: Send Now Playing "+title+" "+artist+" "+timestamp)
    // login first
    // lastfmlogin()
    // send request
    // not ready yetrequest(nowPlayingURL)
}

function listner () {
    console.debug("Debug: I dont know... "+this.responseText)
}

function request(URL) {
    console.debug("Debug: "+URL)
    var https = new XMLHttpRequest(); // create new XMLHttpRequest
    https.onload = listner; // send data over to debugger

    https.open("POST",URL,true); // use post to send to the API URL sync
    https.setRequestHeader("User-Agent", "Music-App/"+appVersion)
    https.send(); // now send the data
    var xmlDoc = https.responseXML;
    console.debug("Debug: answer of call is "+xmlDoc)
}

function authenticate(username,password) {
    // send to scrobble_url
    var params = "?method=auth.getMobileSession&api_key="+api_key+"&api_sig="+secret_key+"&password="+password+"&username="+username
    var signature = auth_signature(username,password)
    var lastfmURL = scrobble_url+params

    // not ready yetrequest(lastfmURL)

    // get response
    //var status = xmlDoc.getElementsByTagName("status")[0].childNodes[0].nodeValue
    //var code = xmlDoc.getElementsByTagName("code")[0].childNodes[0].nodeValue
    // get the token key and save it in variable (is only used once, so new on for each scrobble)
    // get the session key and save in Settings database

    // if correct, print logged in
    console.debug("Debug: Last FM is now authenticated: "+xmlDoc+ "NOT! It's not done yet, stupid ;)")
    //console.debug("Debug: Server said "+status+" and "+code)

    // else print error and tell user to try again
}

// mobile authentication
function auth_signature(username,password) {
    var signature = Qt.md5("api_key"+api_key+"methodauth.getMobileSessionpassword"+password+"username"+username+secret_key)
    return signature
}
