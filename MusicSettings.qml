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
import "scrobble.js" as Scrobble
import "playlists.js" as Playlists
import "meta-database.js" as Library
import "playing-list.js" as PlayingList

Dialog {
    id: root

//    Row {
//        spacing: units.gu(2)
//        Button {
//            id: selectdirectory
//            text: i18n.tr("Select Music folder")
//            width: units.gu(30)
//            color: "#c94212"
//            onClicked: {
//                folderScannerModel.nameFilters = [""]
//                console.debug('Debug: Show settings')
//                pageStack.push(Qt.resolvedUrl("LibraryLoader.qml"))
//                PopupUtils.close(root)
//            }
//        }
//    }

    // Shuffle or not
    Row {
        spacing: units.gu(2)
        Label {
            text: i18n.tr("Shuffle")
            width: units.gu(20)
            color: "white"
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
            color: "white"
        }
        Switch {
            id: scrobbleSwitch
            checked: Settings.getSetting("scrobble") === "1"
        }
    }

    Row {
        spacing: units.gu(2)
        Button {
            id: lastfmLogin
            text: i18n.tr("Login to last.fm")
            width: units.gu(30)
            color: "#c94212"
            enabled: Settings.getSetting("scrobble") === "1" // only if scrobble is activated.
            onClicked: {
                PopupUtils.open(Qt.resolvedUrl("LoginLastFM.qml"), mainView,
                                {
                                    title: i18n.tr("Last.fm")
                                } )
            }
        }
    }

    // import playlists from lastfm
    Row {
        spacing: units.gu(2)
        Button {
            id: lastfmPlaylists
            text: i18n.tr("Import playlists from last.fm")
            width: units.gu(30)
            color: "#c94212"
            enabled: Settings.getSetting("scrobble") === "1" // only if scrobble is activated.
            onClicked: {
                console.debug("Debug: import playlists from last.fm")
                Scrobble.getPlaylists(Settings.getSetting("lastfmusername"))
            }
        }
    }

    // headphones
    Row {
        spacing: units.gu(2)
        Label {
            text: i18n.tr("Pause when when headphones are un-plugged.")
            width: units.gu(20)
            wrapMode: "WordWrap"
            color: "white"
        }
        Switch {
            checked: true
            enabled: false
        }
    }

    // developer button
    /*Button {
        text: i18n.tr("Clean everything!")
        color: "red"
        onClicked: {
            Settings.reset()
            Library.reset()
            Playlists.reset()
        }
    }*/

    Button {
        text: i18n.tr("Close")
        onClicked: {
            PopupUtils.close(root)
            console.debug("Debug: Close settings")
            // push infront the tracks again
            // set new music dir
            Settings.initialize()
            //Settings.setSetting("currentfolder", musicDirField.text) // save music dir
            Settings.setSetting("shuffle", shuffleSwitch.checked) // save shuffle state
            Settings.setSetting("scrobble", scrobbleSwitch.checked) // save shuffle state
            random = shuffleSwitch.checked // set shuffle state variable
            scrobble = scrobbleSwitch.checked // set scrobble state variable
            // set function to set and load tracks in new map directly, whithout need of restart
            // disable fpr now (testing) console.debug("Debug: Set new music dir to: "+musicDirField.text)
            console.debug("Debug: Shuffle: "+ shuffleSwitch.checked)
            console.debug("Debug: Scrobble: "+ scrobbleSwitch.checked)
        }
    }

}
