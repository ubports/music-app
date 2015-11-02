/*
 * Copyright (C) 2015
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
import Ubuntu.Content 1.1
import Ubuntu.MediaScanner 0.1
import Ubuntu.Thumbnailer 0.1

import "../components"
import "../components/Delegates"
import "../components/Flickables"
import "../components/HeadState"


MusicPage {
    id: contentHubExportPage
    title: i18n.tr("Export Song")
    searchResultsCount: songsModelFilter.count
    showToolbar: false
    state: "default"
    states: [
        PageHeadState {
            id: defaultState
            name: "default"
            actions: [
                tickAction,
                searchAction,
            ]
            backAction: Action {
                iconName: "close"
                onTriggered: {
                    transfer.items = [];
                    transfer.state = ContentTransfer.Aborted;

                    mainPageStack.pop()
                }
            }

            PropertyChanges {
                target: contentHubExportPage.head
                backAction: defaultState.backAction
                actions: defaultState.actions
            }
        },
        SearchHeadState {
            id: searchHeader
            actions: [
                tickAction,
            ]
            thisPage: contentHubExportPage

            onQueryChanged: trackList.clearSelection()
        }
    ]
    transitions: [
        Transition {
            from: "search"
            to: "default"
            ScriptAction {
                script: trackList.clearSelection()
            }
        }
    ]


    Action {
        id: searchAction
        enabled: songsModelFilter.count > 0
        iconName: "search"
        onTriggered: contentHubExportPage.state = "search"
    }
    Action {
        id: tickAction
        enabled: trackList.getSelectedIndices().length > 0
        iconName: "tick"
        onTriggered: {
            var items = [];
            var indicies = trackList.getSelectedIndices();

            for (var i=0; i < indicies.length; i++) {
                items.push(contentItemComponent.createObject(contentHubExportPage, {url: songsModelFilter.get(indicies[i]).filename}));
            }

            transfer.items = items;
            transfer.state = ContentTransfer.Charged;

            mainPageStack.pop()
        }
    }

    property var contentItemComponent
    property var transfer
    readonly property bool singular: transfer ? transfer.selectionType === ContentTransfer.Single : false

    MultiSelectListView {
        id: trackList
        anchors {
            bottomMargin: units.gu(2)
            fill: parent
            topMargin: units.gu(2)
        }
        model: SortFilterModel {
            id: songsModelFilter
            property alias rowCount: songsModel.rowCount
            model: SongsModel {
                id: songsModel
                store: musicStore
            }
            sort.property: "title"
            sort.order: Qt.AscendingOrder
            sortCaseSensitivity: Qt.CaseInsensitive
            filter.property: "title"
            filter.pattern: new RegExp(searchHeader.query, "i")
            filterCaseSensitivity: Qt.CaseInsensitive
        }
        ViewItems.selectMode: true

        property int selectedCache: -1

        delegate: MusicListItem {
            id: track
            objectName: "tracksPageListItem" + index
            column: Column {
                Label {
                    id: trackTitle
                    color: styleMusic.common.music
                    fontSize: "small"
                    objectName: "tracktitle"
                    text: model.title
                }

                Label {
                    id: trackArtist
                    color: styleMusic.common.subtitle
                    fontSize: "x-small"
                    text: model.author
                }
            }
            height: units.gu(7)
            imageSource: {"art": model.art}
            multiselectable: true

            onSelectedChanged: {
                if (singular && selected && (trackList.selectedCache === -1 || trackList.selectedCache !== index)) {
                    trackList.ViewItems.selectedIndices = [index];
                    trackList.selectedCache = index;
                } else if (singular && !selected && trackList.selectedCache === index) {
                    trackList.selectedCache = -1;
                }
            }
        }

        Component.onCompleted: state = "multiselectable"
    }
}
