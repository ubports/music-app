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

import QtQuick 2.2
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 0.1
import Ubuntu.Components.Popups 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import QtQuick.XmlListModel 2.0
import "settings.js" as Settings
import "scrobble.js" as Scrobble

// Last.fm login dialog
DefaultSheet {
    id: lastfmroot
    contentsHeight: parent.height;

    onDoneClicked: {
        customdebug("Close lastfm sheet.")
        PopupUtils.close(lastfmroot)
    }

    onVisibleChanged: {
        if (visible) {
            musicToolbar.setSheet(lastfmroot)
        }
        else {
            musicToolbar.removeSheet(lastfmroot)
        }
    }

    // Dialog data
    title: i18n.tr("Last.fm")

    Column {
        spacing: units.gu(2)

        Label {
            text: i18n.tr("Login to be able to scrobble.")
        }

        // Username field
        TextField {
                id: usernameField
                KeyNavigation.tab: passField
                hasClearButton: true
                placeholderText: i18n.tr("Username")
                text: lastfmusername
                width: units.gu(48)
        }

        // add password field
        TextField {
            id: passField
            KeyNavigation.backtab: usernameField
            hasClearButton: true
            placeholderText: i18n.tr("Password")
            text: lastfmpassword
            echoMode: TextInput.Password
            width: units.gu(48)
        }

        // indicate progress of login
        ActivityIndicator {
            id: activity
            visible: false
        }

        // item to present login result
        ListItem.Standard {
            id: loginstatetext
            visible: false
        }

        // Login button
        Button {
            id: loginButton
            width: units.gu(48)
            text: i18n.tr("Login")
            enabled: false

            onClicked: {
                activity.visible = true
                activity.running = !activity.running // change the activity indicator state
                loginstatetext.visible = true
                loginstatetext.text = i18n.tr("Trying to login...")
                Settings.initialize()
                console.debug("Debug: Login to Last.fm clicked.")
                // try to login
                Settings.setSetting("lastfmusername", usernameField.text) // save lastfm username
                Settings.setSetting("lastfmpassword", passField.text) // save lastfm password (should be passed by ha hash function)
                lastfmusername = Settings.getSetting("lastfmusername") // get username again
                lastfmpassword = Settings.getSetting("lastfmpassword") // get password again, for use during the rest of the session
                if (usernameField.text.length > 0 && passField.text.length > 0) { // make sure something is acually inputed
                    console.debug("Debug: Sending credentials to authentication function");
                    var answer = Scrobble.authenticate(usernameField.text, passField.text) // pass credentials to login function

                    // Print result to user
                    if (answer == "ok") {
                        loginstatetext.text = i18n.tr("Login Successful")
                        activity.running = !activity.running // change the activity indicator state
                        //loginButton.text = "Log out" // later
                        Settings.setSetting("lastfmsessionkey",Scrobble.session_key)
                    }
                    else {
                        loginstatetext.text = i18n.tr("Login Failed")
                        activity.running = !activity.running // change the activity indicator state
                    }

                }
                else {
                    loginstatetext.text = i18n.tr("You forgot to set your username and/or password")
                }
            }
        }
    }
}
