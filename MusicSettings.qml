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

ComposerSheet {
    id: musicSettings
    title: i18n.tr("Settings")
    contentsHeight: parent.height;

    onCancelClicked: PopupUtils.close(musicSettings)
    onConfirmClicked: {
        PopupUtils.close(musicSettings)
        console.debug("Debug: Save settings")
        Settings.initialize()

        // Equaliser
        // ACTIVATE IN 1.+ Settings.setSetting("eqialiser",equaliser.index)

        // snap track
        Settings.setSetting("snaptrack",snapSwitch.checked)

        // ACCOUNTS
        // Last.fm

        // MUSIC STREAMING
        // Ubuntu one
        /* READY THIS LATER IN 1.+
        if (ubuntuaccount === activated) {
            Settings.setSetting("wifiswitch",wifiSwitch.checked)
        }*/


        // MOVE TO TOOLBAR
        Settings.setSetting("shuffle", shuffleSwitch.checked) // save shuffle state

        // -- random = shuffleSwitch.checked // set shuffle state variable
        //console.debug("Debug: Shuffle: "+ shuffleSwitch.checked)

        // MOVE TO scrobble Settings.setSetting("scrobble", scrobbleSwitch.checked) // save shuffle state
        //scrobble = scrobbleSwitch.checked // set scrobble state variable
        //console.debug("Debug: Scrobble: "+ scrobbleSwitch.checked)
    }

    Column {
        spacing: units.gu(2)
        width: parent.width

        // Activate in 1.+
        ListItem.ItemSelector {
            id: equaliser
            enabled: false
            visible: false
            text: i18n.tr("Equaliser")
            model: [i18n.tr("Default"),
                  i18n.tr("Accoustic"),
                  i18n.tr("Classical"),
                  i18n.tr("Electronic"),
                  i18n.tr("Flat"),
                  i18n.tr("Hip Hop"),
                  i18n.tr("Jazz"),
                  i18n.tr("Metal"),
                  i18n.tr("Pop"),
                  i18n.tr("Rock"),
                  i18n.tr("Custom")]
            onDelegateClicked: {
                customdebug("Value changed to "+index)
                //equaliserChange(index)
            }
        }

        // Snap to current track
        Row {
            spacing: units.gu(2)
            width: parent.width
            anchors.top: equaliser.bottom
            Label {
                id: snapLabel
                text: i18n.tr("Snap to current song \nwhen opening toolbar")
                color: styleMusic.musicSettings.labelColor
            }
            Switch {
                id: snapSwitch
                checked: Settings.getSetting("snaptrack") === "1"
                anchors.right: parent.right
            }
        }

        // Shuffle or not
        // MOVE THIS TO NEW TOOLBAR
        Row {
            id: shuffleRow
            spacing: units.gu(2)
            width: parent.width
            Label {
                id: shuffleLabel
                text: i18n.tr("Shuffle")
                color: styleMusic.musicSettings.labelColor
                // make it stawy to the right with a certain margin
            }
            Switch {
                id: shuffleSwitch
                checked: Settings.getSetting("shuffle") === "1"
                anchors.right: parent.right
            }
        }

        // Accounts
        Column {
            id: accountsColumn
            spacing: units.gu(2)
            anchors.top: shuffleRow.bottom
            anchors.topMargin: units.gu(20)
            Label {
                text: i18n.tr("Accounts")
                color: styleMusic.musicSettings.labelColor
            }

            // lastfm
            ListItem.Subtitled {
                id: lasftfmProg
                text: i18n.tr("Last.fm")
                subText: i18n.tr("Login to scrobble and \nimport playlists")
                width: parent.width
                progression: true
                enabled: true
                visible: false
                onClicked: {
                    PopupUtils.open(Qt.resolvedUrl("LoginLastFM.qml"), mainView,
                                    {
                                        title: i18n.tr("Last.fm")
                                    } )
                    PopupUtils.close(musicSettings)
                }
            }
        }

        // Music Streaming
        // Activate in 1.+
        Column {
            id: streamingColumn
            spacing: units.gu(2)
            anchors.top: accountsColumn.bottom
            anchors.topMargin: units.gu(20)
            Label {
                text: i18n.tr("Music Streaming")
                color: styleMusic.musicSettings.labelColor
                visible: true
            }

            Column {
                // Ubuntu One
                ListItem.Subtitled {
                    id: musicStreamProg
                    text: i18n.tr("Ubuntu One")
                    subText: i18n.tr("Sign in to stream your cloud music")
                    enabled: false
                    visible: false
                    progression: true
                    onClicked: {
                        customdebug("I'm Ron Burgendy...?")
                    }
                }

                Row {
                    spacing: units.gu(2)
                    Label {
                        id: streamwifiLabel
                        text: i18n.tr("Stream only on Wi-Fi")
                        color: styleMusic.musicSettings.labelColor
                        enabled: false // check if account is connected
                        visible: false
                    }
                    Switch {
                        id: wifiSwitch
                        checked: Settings.getSetting("wifiswitch") === "1"
                        enabled: false // check if account is connected
                        visible: false
                        //anchors.right: parent.right
                    }
                }
            }
        }

        /* MOVE THIS STUFF
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
        Button {
            text: i18n.tr("Clean everything!")
            color: "red"
            visible: false
            onClicked: {
                Settings.reset()
                Playlists.reset()
            }
        }
    }
}
