/*
 * Copyright (C) 2016
 *      Andrew Hayzen <ahayzen@gmail.com>
 *      Victor Thompson <victor.thompson@gmail.com>
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

import QtQuick 2.4
import Ubuntu.Components 1.3


State {
    name: "default"

    property PageHeader thisHeader: PageHeader {
        id: headerState
        flickable: thisPage.flickable
        leadingActionBar {
            actions: {
                if (mainPageStack.currentPage === tabs) {
                    tabs.tabActions
                } else if (mainPageStack.depth > 1) {
                    backActionComponent
                }
            }
        }
        title: thisPage.title
        trailingActionBar {
            actions: [
                Action {
                    enabled: !player.mediaPlayer.playlist.empty
                    iconName: "add-to-playlist"
                    // TRANSLATORS: this action appears in the overflow drawer with limited space (around 18 characters)
                    text: i18n.tr("Add to playlist")

                    onTriggered: {
                        var items = []

                        items.push(makeDict(player.metaForSource(player.mediaPlayer.playlist.currentItemSource)));

                        mainPageStack.push(Qt.resolvedUrl("../../ui/AddToPlaylist.qml"),
                                           {"chosenElements": items})
                    }
                },
                Action {
                    enabled: !player.mediaPlayer.playlist.empty
                    iconName: "delete"
                    objectName: "clearQueue"
                    // TRANSLATORS: this action appears in the overflow drawer with limited space (around 18 characters)
                    text: i18n.tr("Clear queue")

                    onTriggered: player.mediaPlayer.playlist.clearWrapper()
                }
            ]
        }
        visible: thisPage.state === "default"

        Action {
            id: backActionComponent
            iconName: "back"
            onTriggered: mainPageStack.pop()
        }

        StyleHints {
            backgroundColor: mainView.headerColor
            dividerColor: Qt.darker(mainView.headerColor, 1.1)
        }
    }
    property Item thisPage

    PropertyChanges {
        target: thisPage
        header: thisHeader
    }
}
