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
import Ubuntu.Components 1.2
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
    state: "default"
    states: [
        PageHeadState {
            id: defaultState
            name: "default"
            actions: [
                Action {
                    iconName: "tick"
                    onTriggered: {
                        var items = [];

                        for (var i=0; i < trackList.selectedItems.length; i++) {
                            items.push(contentItemComponent.createObject(contentHubExportPage, {url: songsModelFilter.get(trackList.selectedItems[i]).filename}));
                        }

                        transfer.items = items;
                        transfer.state = ContentTransfer.Charged;

                        mainPageStack.pop()
                    }
                },
                Action {
                    id: searchAction
                    enabled: songsModelFilter.count > 0
                    iconName: "search"
                    onTriggered: contentHubExportPage.state = "search"
                }
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
            thisPage: contentHubExportPage
        }
    ]

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

        property int singularCache: -1

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
            selectionMode: true

            onSelectedChanged: {
                // in singular mode only allow one item to be selected
                if (singular && selected && trackList.singularCache === -1) {
                    trackList.singularCache = index;

                    trackList.clearSelection();
                    selected = true;

                    trackList.singularCache = -1;
                }
            }
        }

        Component.onCompleted: state = "multiselectable"
    }
}
