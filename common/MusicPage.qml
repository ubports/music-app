/*
 * Copyright (C) 2013, 2014
 *      Andrew Hayzen <ahayzen@gmail.com>
 *      Daniel Holm <d.holmen@gmail.com>
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

import QtQuick 2.3
import Ubuntu.Components 1.1


// generic page for music, could be useful for bottomedge implementation
Page {
    id: thisPage
    anchors {
        bottomMargin: musicToolbar.visible ? musicToolbar.currentHeight : 0
        fill: parent
    }

    property string searchValue: thisPage.state === "search" ? searchField.text : ""
    property bool searchablePage: false
    property alias searchActionLink: searchAction

    Action {
        id: searchAction
        iconName: "search"
        onTriggered: {
            thisPage.state = "search"
            searchField.focus = true
        }
    }

    head.actions: searchablePage ? [ searchAction ] : []

    state: ""
    states: [
        State {
            name: ""
            PropertyChanges {
                target: thisPage.head
                // needed otherwise actions will not be
                // returned to its original state.
                actions: searchablePage ? [ searchAction ] : []
            }
        },
        PageHeadState {
            id: headerState
            name: "search"
            head: thisPage.head
            backAction: Action {
                id: leaveSearchAction
                text: "back"
                iconName: "back"
                onTriggered: {
                    thisPage.state = ""
                    searchField.text = ""
                }
            }
            contents: TextField {
                id: searchField
                anchors {
                    right: parent ? parent.right : undefined
                    rightMargin: units.gu(1)
                }
                hasClearButton: true
                inputMethodHints: Qt.ImhNoPredictiveText
                placeholderText: i18n.tr("Search...")
            }
        }
    ]

    // FIXME: hack as a workaround to SDK header switching issue pad.lv/1341814
    property Item __oldContents: null

    Connections {
        target: thisPage.head
        onContentsChanged: {
            if (thisPage.__oldContents) {
                thisPage.__oldContents.parent = null;
            }
            thisPage.__oldContents = thisPage.head.contents;
        }
    }

    onVisibleChanged: {
        if (visible) {
            musicToolbar.setPage(thisPage);
        } else {
            thisPage.state = ""
            searchField.text = ""
        }
    }
}
