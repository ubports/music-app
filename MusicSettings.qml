/*
 * Copyright (C) 2013 Andrew Hayzen <ahayzen@gmail.com>
 *                    Daniel Holm <d.holmen@gmail.com>
 *                    Victor Thompson <victor.thompson@gmail.com>
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

ComposerSheet {
    id: musicSettings
    title: i18n.tr("Settings")

    onCancelClicked: PopupUtils.close(musicSettings)
    onConfirmClicked: {
        PopupUtils.close(musicSettings)
        console.debug("Debug: Save settings")
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

    Column {
        spacing: units.gu(2)

        ListItem.ItemSelector {
            id: equaliser
            text: i18n.tr("Equaliser")
            model: [i18n.tr("Normal"),
                  i18n.tr("Rock"),
                  i18n.tr("Pop"),
                  i18n.tr("House"),
                  i18n.tr("Jazz")]
            onClicked: {
                customdebug("User clicked on the title itself. I'm Ron Burgendy...?")
            }
            onDelegateClicked: {
                customdebug("Value changed to "+index)
                //equaliserChange(index)
            }
        }

        // Snap to current track
        Row {
            spacing: units.gu(20)
            Label {
                text: i18n.tr("Snap to current song \nwhen opening toolbar")
            }
            Switch {
                id: snapSwitch
                checked: true
            }
        }

        // Accounts
        Label {
            text: i18n.tr("Accounts")
        }

        // lastfm
        ListItem.Subtitled {
            id: lasftfmProg
            text: i18n.tr("Last.fm")
            subText: i18n.tr("Login to scrobble and \nimport playlists")
            progression: true
            onClicked: {
                customdebug("I'm Ron Burgendy...?")
            }
        }

        // Music Streaming
        Label {
            text: i18n.tr("Music Streaming")
        }

        Column {

            ListItem.Subtitled {
                id: musicStreamProg
                text: i18n.tr("Ubuntu One")
                subText: i18n.tr("Sign in to stream your cloud music")
                progression: true
                onClicked: {
                    customdebug("I'm Ron Burgendy...?")
                }
            }

            Row {
                spacing: units.gu(20)
                Label {
                    text: i18n.tr("Stream only on Wi-Fi")
                    enabled: false // check if account is connected
                }
                Switch {
                    id: wifiSwitch
                    checked: true
                    enabled: false // check if account is connected
                }
            }
        }

        /* MOVE THIS STUFF
        // Shuffle or not
        Row {
            spacing: units.gu(2)
            width: parent.width
            Label {
                text: i18n.tr("Shuffle")
                width: units.gu(20)
            }
            Switch {
                id: shuffleSwitch
                checked: Settings.getSetting("shuffle") === "1"
            }
        }

        Row {
            spacing: units.gu(2)
            Label {
                text: i18n.tr("Scrobble to Last.FM")
                width: units.gu(20)
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
        } */

        // developer button - KILLS YOUR CAT!
        /*Button {
            text: i18n.tr("Clean everything!")
            color: "red"
            onClicked: {
                Settings.reset()
                Library.reset()
                Playlists.reset()
            }
        }*/
    }
}
