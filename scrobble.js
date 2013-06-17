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

/*import QtQuick 2.0
import QtQuick.LocalStorage 2.0
import QtQuick.XmlListModel 2.0
import "settings.js" as Settings
import "meta-database.js" as Library*/

// VARIABLES
var api_key = "07c14de06e622165b5b4d55deb85f4da"
var secret_key = "14125657da06bcb14919e23e2f09de32"
var scrobble_url = "http://ws.audioscrobbler.com/2.0/"

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

// scrobble track
function scobble(track,timestamp) {
    var artist = getMetadata(track,artist)
    var title = getMetadata(track,title)
    console.debug("Debug: Scrobble "+title+" "+artist+" "+timestamp)
    // login first
    // lastfmlogin()
    // send
    // rpcRequest()
}

function now_playing(track,timestamp) {
    var artist = getMetadata(track,artist)
    var title = getMetadata(track,title)
    console.debug("Debug: Send Now Playing "+title+" "+artist+" "+timestamp)
    // login first
    // lastfmlogin()
    // send
    // rpcRequest()
}

function lastfmlogin() {
    // get signature
    auth_signature(lastfmusername,lastfmpassword)
    // send to scrobble_url
    // get response
    // if correct, print logged in
    // else print error and tell user to try again
}

// mobile authentication
function auth_signature(username,password) {
    var signature = Qt.md5("api_key"+api_key+"methodauth.getMobileSessionpassword"+password+"username"+username+secret_key)
    return signature
}

/*
    // Model to send the data
    XmlListModel {
        id: scrobblemodel
        query: "/"

        function rpcRequest(request,handler) {
            var http = new XMLHttpRequest()

            http.open("POST",scrobble_url,true)
            http.setRequestHeader("User-Agent", "Music-App/"+appVersion)
            http.setRequestHeader("Content-type", "text/xml")
            http.setRequestHeader("Content-length", request.length)
            if (root.authenticate) {
                http.setRequestHeader("Authorization", "Basic " + Qt.btoa(lastfmusername+":"+lastfmusername))
            }
            http.setRequestHeader("Connection", "close")
            http.onreadystatechange = function() {
                if(http.readyState == 4 && http.status == 200) {
                    console.debug("Debug: XmlRpc::rpcRequest.onreadystatechange()")
                    handler(http.responseText)
                }
            }
            http.send(request)
        }

        function callHandler(response) {
            xml = response
        }

        function call(cmd,params) {
            console.debug("Debug: XmlRpc.call(",cmd,params,")")
            var request = ""
            request += "<?xml version='1.0'?>"
            request += "<methodCall>"
            request += "<methodName>" + cmd + "</methodName>"
            request += "<params>"
            for (var i=0; i<params.length; i++) {
            request += "<param><value>"
            if (typeof(params[i])=="string") {
                request += "<string>" + params[i] + "</string>"
            }
            if (typeof(params[i])=="number") {
                request += "<int>" + params[i] + "</int>"
            }
            request += "</value></param>"
            }
            request += "</params>"
            request += "</methodCall>"
            rpcRequest(request,callHandler)
        }
    }
*/
