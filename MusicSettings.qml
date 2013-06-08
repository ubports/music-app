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
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Components.Popups 0.1
import QtQuick.LocalStorage 2.0
import "settings.js" as Settings

Dialog {
    id: root

    Row {
        spacing: units.gu(2)
        Button {
            id: selectdirectory
            text: i18n.tr("Select Music folder")
            width: units.gu(20)
            color: "#c94212"
            onClicked: {
                pageStack.push(Qt.resolvedUrl("LibraryLoader.qml"))
                PopupUtils.close(root)
            }
        }
    }

    // Shuffle or not
    Row {
        spacing: units.gu(2)
        Label {
            text: i18n.tr("Shuffle")
            width: units.gu(20)
        }
        Switch {
            id: shuffleSwitch
            checked: Settings.getSetting("shuffle") === "1"
        }
    }

    // lastfm
    Row {
        spacing: units.gu(2)
        Label {
            text: i18n.tr("Scrobble to Last.FM")
            width: units.gu(20)
        }
        Switch {
            checked: false
            enabled: false
        }
    }

    Row {
        Button {
            id: lastfmlogin
            text: i18n.tr("Login to Last.FM")
            width: units.gu(20)
            color: "#c94212"
            //onClicked: PopupUtils.open(lastfmButton, lastfmlogin)
        }
    }

    // headphones
    Row {
        spacing: units.gu(2)
        Label {
            text: i18n.tr("Pause when when headphones are un-plugged.")
            width: units.gu(20)
        }
        Switch {
            checked: true
            enabled: false
        }
    }

    // LastFM settings
    Component {
        id: lastfmButton
        DefaultSheet {
            id: sheet
            title: "Login to Last.FM"
            doneButton: true
            // I want them both! cancelButton: true

            Row {
                // Username field
                TextField {
                        id: usernameField
                        KeyNavigation.tab: passField
                        hasClearButton: true
                        placeholderText: i18n.tr("LastFM username")
                        width: units.gu(40)
                }
            }

            Row {
                // add password field
                TextField {
                    id: passField
                    KeyNavigation.backtab: usernameField
                    hasClearButton: true
                    placeholderText: i18n.tr("LastFM password")
                    echoMode: TextInput.Password
                    width: units.gu(40)
                }
            }

        }
    }
    Button {
        text: i18n.tr("Close")
        onClicked: {
            PopupUtils.close(root)
            // set new music dir
            Settings.initialize()
            //Settings.setSetting("currentfolder", musicDirField.text) // save music dir
            Settings.setSetting("shuffle", shuffleSwitch.checked) // save shuffle state
            random = shuffleSwitch.checked
            console.debug("Debug: Set new music dir to: "+musicDirField.text)
            console.debug("Debug: Shuffle: "+ shuffleSwitch.checked)
        }
    }

}
