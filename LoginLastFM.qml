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
import "settings.js" as Settings
import "meta-database.js" as Library
import "playing-list.js" as PlayingList

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

    // Login button
    Row {
        Button {
            id: loginButton
            width: units.gu(30)
            text: "Login"
            color: "#c94212"
            onClicked: {
                Settings.initialize()
                console.debug("Debug: Login to LastFM clicked.")
                // try to login
                Settings.setSetting("lastfmusername", usernameField.text) // save lastfm username
                Settings.setSetting("lastfmpassword", passField.text) // save lastfm password (should be passed by ha hash function)
<<<<<<< TREE
                lastfmusername = Settings.getSetting("lastfmusername") // get username again
                lastfmpassword = Settings.getSetting("lastfmpassword") // get password again
                PopupUtils.close(lastfmroot)
=======
                PopupUtils.open(Qt.resolvedUrl("MusicSettings.qml"), mainView,
                            {
                                title: i18n.tr("Settings")
                            } )
>>>>>>> MERGE-SOURCE
            }
        }
    }

    // cancel Button
    Row {
        Button {
            id: cancelButton
            width: units.gu(30)
            text: "Cancel"
            onClicked: {
                PopupUtils.close(lastfmroot)
<<<<<<< TREE
=======
                PopupUtils.open(Qt.resolvedUrl("MusicSettings.qml"), mainView,
                            {
                                title: i18n.tr("Settings")
                            } )
>>>>>>> MERGE-SOURCE
            }
        }
    }
}



