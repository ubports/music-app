/*
 * Copyleft Daniel Holm.
 *
 * Authors:
 *  Daniel Holm <d.holmen@gmail.com>
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

Dialog {
    id: root

    // lastfm
    Row {
        spacing: units.gu(2)
        Label {
            text: i18n.tr("Scrobble to Last.FM")
            width: units.gu(35)
        }
        Switch {
            checked: false
        }
    }

    Row {
        Button {
            id: lastfmlogin
            text: i18n.tr("Login to Last.FM")
            width: units.gu(20)
            color: "#c94212"
            onClicked: PopupUtils.open(lastfmButton, lastfmlogin)
        }
    }

    // headphones
    Row {
        spacing: units.gu(2)
        Label {
            text: i18n.tr("Pause when when headphones are un-plugged.")
            width: units.gu(35)
        }
        Switch {
            checked: true
        }
    }

    // About this application
    Row {
        spacing: units.gu(2)
        Button {
            text: i18n.tr("About")
            color: "#c94212"
            width: units.gu(20)
            onClicked: print("clicked About Button")
        }
    } // close about row

    // LastFM settings
    Component {
        id: lastfmButton
        DefaultSheet {
            id: sheet
            title: "Login to Last.FM"
            doneButton: true
            // I want them both! cancelButton: true

            // Username field
            TextField {
                    id: usernameField
                    KeyNavigation.tab: passField
                    hasClearButton: true
                    placeholderText: i18n.tr("LastFM username")
                    width: units.gu(40)
            }

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
