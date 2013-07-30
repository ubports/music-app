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

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1
import Ubuntu.Components.Popups 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import org.nemomobile.folderlistmodel 1.0
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import QtQuick.XmlListModel 2.0
import "settings.js" as Settings
import "meta-database.js" as Library
import "scrobble.js" as Scrobble

// LastFM login dialog
Dialog {
    id: lastfmroot
    anchors.fill: parent

    // Dialog data
    title: i18n.tr("LastFM")
    text: i18n.tr("Login to be able to scrobble.")

    Row {
        // Username field
        TextField {
                id: usernameField
                KeyNavigation.tab: passField
                hasClearButton: true
                placeholderText: i18n.tr("Username")
                text: lastfmusername
                width: units.gu(30)
        }
    }

    Row {
        // add password field
        TextField {
            id: passField
            KeyNavigation.backtab: usernameField
            hasClearButton: true
            placeholderText: i18n.tr("Password")
            text: lastfmpassword
            echoMode: TextInput.Password
            width: units.gu(30)
        }
    }

    Row {
        // indicate progress of login
        ActivityIndicator {
            id: activity
        }

        // item to present login result
        ListItem.Standard {
            id: loginstatetext
        }

        // Model to send the data
        XmlListModel {
            id: lastfmlogin
            query: "/"

            function rpcRequest(request,handler) {
                console.debug("Debug: Starting to send user credentials")
                var http = new XMLHttpRequest()

                http.open("POST",Scrobble.scrobble_url,true)
                http.setRequestHeader("User-Agent", "Music-App/"+appVersion)
                http.setRequestHeader("Content-type", "text/xml")
                http.setRequestHeader("Content-length", request.length)
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
    }

    // Login button
    Row {
        Button {
            id: loginButton
            width: units.gu(30)
            text: "Login"
            color: "#c94212"
            onClicked: {
                activity.running = !activity.running // change the activity indicator state
                loginstatetext.text = i18n.tr("Trying to login...")
                Settings.initialize()
                console.debug("Debug: Login to LastFM clicked.")
                // try to login
                Settings.setSetting("lastfmusername", usernameField.text) // save lastfm username
                Settings.setSetting("lastfmpassword", passField.text) // save lastfm password (should be passed by ha hash function)
                lastfmusername = Settings.getSetting("lastfmusername") // get username again
                lastfmpassword = Settings.getSetting("lastfmpassword") // get password again
                if (usernameField.text.length > 0 && passField.text.length > 0) { // make sure something is acually inputed
                    console.debug("Debug: Sending credentials to authentication function")
                    var signature = Scrobble.authenticate(usernameField.text, passField.text); // pass the data to authenticate
                    //lastfmlogin.model
                    //lastfmlogin.construct()
                }
                else {
                    loginstatetext.text = i18n.tr("You forgot to set your username and/or password")
                }
            }
        }
    }

    // cancel Button
    Row {
        Button {
            id: cancelButton
            width: units.gu(30)
            text: i18n.tr("Close")
            onClicked: {
                PopupUtils.close(lastfmroot)
            }
        }
    }
}



