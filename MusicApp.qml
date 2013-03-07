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
import Ubuntu.Components.ListItems 0.1 as ListItem

MainView {
    objectName: i18n.tr("Music Player")

    width: units.gu(50)
    height: units.gu(75)

    Tabs {
        id: tabs
        anchors.fill: parent

        // 0 tab
        /*
        Tab {
            objectName: "Playlist tab"

            title: i18n.tr("Playlists")
            page: Page {
                anchors.margins: units.gu(2)

                tools: ToolbarActions {
                    Action {
                        objectName: "action"

                        iconSource: Qt.resolvedUrl("avatar.png")
                        text: i18n.tr("Create new")

                        onTriggered: {
                            label.text = i18n.tr("New playlist tapped")
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    Label {
                        id: toolbar_playlist
                        objectName: "Playlist Toolbar"

                        text: i18n.tr("List all playlists.")
                    }
                }
            }
        }
        */

        // First tab begins here - should be the primary tab
        Tab {
            objectName: "Tab1"

            title: i18n.tr("Playing")

            // Tab content begins here
            page: Page {
                // toolbar
                tools: ToolbarActions {

                    // Share
                    Action {
                        objectName: "share"

                        iconSource: Qt.resolvedUrl("images/icon_share@20.png")
                        text: i18n.tr("Share")

                        onTriggered: {
                            print = i18n.tr("Share pressed")
                        }
                    }

                    // prevous track
                    Action {
                        objectName: "prev"

                        iconSource: Qt.resolvedUrl("images/prev.png")
                        text: i18n.tr("Previous")

                        onTriggered: {
                            label.text = i18n.tr("Prev track pressed")
                        }
                    }

                    // Play or pause
                    Action {
                        objectName: "plaus"

                        iconSource: Qt.resolvedUrl("images/icon_play@20.png")
                        text: i18n.tr("Play")

                        onTriggered: {
                            label.text = i18n.tr("Play pressed")
                            // should also change button to pause icon
                        }
                    }

                    // Next track
                    Action {
                        objectName: "next"

                        iconSource: Qt.resolvedUrl("images/next.png")
                        text: i18n.tr("Next")

                        onTriggered: {
                            label.text = i18n.tr("Next track pressed")
                        }
                    }

                    // Settings
                    Action {
                        objectName: "settings"

                        iconSource: Qt.resolvedUrl("images/icon_settings@20.png")
                        text: i18n.tr("Settings")

                        onTriggered: {
                            print("Settings pressed")
                            // show settings page
                            pageStack.push(Qt.resolvedUrl("MusicSettings.qml")) // resolce pageStack issue
                        }
                    }
                }
                Column {
                    id: pageLayout

                    anchors {
                        fill: parent
                        margins: root.margins
                        topMargin: title.height
                    }
                    spacing: units.gu(1)

                    // placeholder
                    Row {
                        spacing: units.gu(1)
                        Label {
                            text: "Press album art once to pause, \ndoubble tap to next track, hold to previous."
                        }
                    }

                    Row {
                        spacing: units.gu(1)
                        // Album cover here
                        UbuntuShape {
                            width: units.gu(50)
                            height: units.gu(50)
                            image: Image {
                                source: "images/music.png"
                                fillMode: Image.PreserveAspectCrop
                                horizontalAlignment: Image.AlignHCenter
                                verticalAlignment: Image.AlignVCenter
                            }
                        }
                    }

                    // track progress
                    Row {
                        width: units.gu(40)
                        ProgressBar {
                            indeterminate: true
                        }
                    }
                }
            }
        }

        // Second tab begins here
        Tab {
            objectName: "Artists Tab"

            title: i18n.tr("Artists")
            page: Page {
                anchors.margins: units.gu(2)

            // foreach artist:
            ListItem.Standard {
                height: units.gu(4)
                // when pressed on this row, change to albums of artist
                Row {
                    Label {
                        text: i18n.tr("Artist 1")
                        fontSize: large
                    }
                }
            }

                // toolbar
                tools: ToolbarActions {

                    // Share
                    Action {
                        objectName: "share"

                        iconSource: Qt.resolvedUrl("images/share-app.png")
                        text: i18n.tr("Share")

                        onTriggered: {
                            label.text = i18n.tr("Share pressed")
                        }
                    }

                    // prevous track
                    Action {
                        objectName: "prev"

                        iconSource: Qt.resolvedUrl("prev.png")
                        text: i18n.tr("Previous")

                        onTriggered: {
                            label.text = i18n.tr("Prev track pressed")
                        }
                    }

                    // Play or pause
                    Action {
                        objectName: "plaus"

                        iconSource: Qt.resolvedUrl("prev.png")
                        text: i18n.tr("Play")

                        onTriggered: {
                            label.text = i18n.tr("Play pressed")
                            // should also change button to pause icon
                        }
                    }

                    // Next track
                    Action {
                        objectName: "next"

                        iconSource: Qt.resolvedUrl("next.png")
                        text: i18n.tr("Next")

                        onTriggered: {
                            label.text = i18n.tr("Next track pressed")
                        }
                    }

                    // Settings
                    Action {
                        objectName: "settings"

                        iconSource: Qt.resolvedUrl("settings.png")
                        text: i18n.tr("Settings")

                        onTriggered: {
                            label.text = i18n.tr("Settings pressed")
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    Label {
                        id: toolbar_artist
                        objectName: "Artist Toolbar"

                        text: i18n.tr("List all artists on device here.")
                    }
                }
            }
        }

        // Third tab begins here
        Tab {
            objectName: "Albums Tab"

            title: i18n.tr("Albums")
            page: Page {
                anchors.margins: units.gu(2)

                ListItem.Standard {
                    height: units.gu(10)
                    // when pressed on this row, change to albums of artist
                    Row {
                        UbuntuShape {
                            objectName: "coverart"
                            image: Image {
                                source: Qt.resolvedUrl("images/default-album.png") // code for automatic download of new cover art
                            }
                        }
                        Label {
                            text: i18n.tr("Album - Artist \nYear")
                            fontSize: large
                        }
                    }
                }

                // toolbar
                tools: ToolbarActions {

                    // Share
                    Action {
                        objectName: "share"

                        iconSource: Qt.resolvedUrl("images/share-app.png")
                        text: i18n.tr("Share")

                        onTriggered: {
                            label.text = i18n.tr("Share pressed")
                        }
                    }

                    // prevous track
                    Action {
                        objectName: "prev"

                        iconSource: Qt.resolvedUrl("prev.png")
                        text: i18n.tr("Previous")

                        onTriggered: {
                            label.text = i18n.tr("Prev track pressed")
                        }
                    }

                    // Play or pause
                    Action {
                        objectName: "plaus"

                        iconSource: Qt.resolvedUrl("prev.png")
                        text: i18n.tr("Play")

                        onTriggered: {
                            label.text = i18n.tr("Play pressed")
                            // should also change button to pause icon
                        }
                    }

                    // Next track
                    Action {
                        objectName: "next"

                        iconSource: Qt.resolvedUrl("next.png")
                        text: i18n.tr("Next")

                        onTriggered: {
                            label.text = i18n.tr("Next track pressed")
                        }
                    }

                    // Settings
                    Action {
                        objectName: "settings"

                        iconSource: Qt.resolvedUrl("settings.png")
                        text: i18n.tr("Settings")

                        onTriggered: {
                            label.text = i18n.tr("Settings pressed")
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    Label {
                        id: toolbar_album
                        objectName: "Album Toolbar"

                        text: i18n.tr("List all albums on device here.")
                    }
                }
            }
        }

        // Fourth tab begins here
        Tab {
            objectName: "Tracks Tab"

            title: i18n.tr("Tracks")
            page: Page {
                anchors.margins: units.gu(2)

            ListItem.Standard {
                height: units.gu(4)
                // when pressed on this row, play track
                Row {
                    Label {
                        text: i18n.tr("Track 1 - Artist X \nYear")
                        fontSize: large
                    }
                }
            }


                // toolbar
                tools: ToolbarActions {

                    // Share
                    Action {
                        objectName: "share"

                        iconSource: Qt.resolvedUrl("images/share-app.png")
                        text: i18n.tr("Share")

                        onTriggered: {
                            label.text = i18n.tr("Share pressed")
                        }
                    }

                    // prevous track
                    Action {
                        objectName: "prev"

                        iconSource: Qt.resolvedUrl("prev.png")
                        text: i18n.tr("Previous")

                        onTriggered: {
                            label.text = i18n.tr("Prev track pressed")
                        }
                    }

                    // Play or pause
                    Action {
                        objectName: "plaus"

                        iconSource: Qt.resolvedUrl("prev.png")
                        text: i18n.tr("Play")

                        onTriggered: {
                            label.text = i18n.tr("Play pressed")
                            // should also change button to pause icon
                        }
                    }

                    // Next track
                    Action {
                        objectName: "next"

                        iconSource: Qt.resolvedUrl("next.png")
                        text: i18n.tr("Next")

                        onTriggered: {
                            label.text = i18n.tr("Next track pressed")
                        }
                    }

                    // Settings
                    Action {
                        objectName: "settings"

                        iconSource: Qt.resolvedUrl("settings.png")
                        text: i18n.tr("Settings")

                        onTriggered: {
                            label.text = i18n.tr("Settings pressed")
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    Label {
                        id: toolbar_track
                        objectName: "Track Toolbar"

                        text: i18n.tr("List all tracks here.")
                    }
                }
            }
        }


    } // tabs
} // main view
