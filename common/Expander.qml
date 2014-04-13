/*
 * Copyright (C) 2014 Andrew Hayzen <ahayzen@gmail.com>
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
import Ubuntu.Components.Popups 0.1

Item {
    id: expander
    property bool addToPlaylist: false
    property bool addToQueue: false
    property alias backgroundOpacity: expandedBackground.opacity
    property int cachedListItemHeight: 0
    property bool deletePlaylist: false
    property bool editPlaylist: false
    property alias expanderButtonWidth: expandableButton.width
    property var listItem: null
    property var model: null
    property bool share: false
    property bool expanderVisible: false

    Component.onCompleted: {
        collapseExpand.connect(onCollapseExpand);
    }

    function onCollapseExpand(indexCol)
    {
        if (expanderVisible) {
            customdebug("auto collapse")
            expanderVisible = false;
        }
    }

    onExpanderVisibleChanged: {
        if (expanderVisible) {
            cachedListItemHeight = listItem.height;

            expandableButton.height = cachedListItemHeight;
            listItem.height += styleMusic.albums.expandHeight;
        }
        else {
            listItem.height -= styleMusic.albums.expandHeight;
            expandableButton.height = listItem.height;
        }
    }

    Rectangle {
        id: expandableButton
        anchors {
            right: parent.right
            top: parent.top
        }
        color: "transparent"
        height: listItem.height
        width: expandableButtonImage.width * 2

        Image {
            id: expandableButtonImage
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }
            source: "../images/dropdown-menu.svg"
            height: styleMusic.common.expandedItem
            objectName: "expanditem"
            rotation: expander.expanderVisible? 180 : 0
            width: styleMusic.common.expandedItem
        }

        MouseArea {
            anchors {
                right: parent.right
                top: parent.top
            }
            height: parent.height
            width: parent.width + units.gu(1)
            onClicked: {
                var expanderState = expander.expanderVisible;

                collapseExpand();
                expander.expanderVisible = !expanderState;
            }
        }
    }

    Rectangle {
        id: expandedContainer
        anchors {
            top: parent.top
            topMargin: cachedListItemHeight
        }
        color: "transparent"
        height: styleMusic.albums.expandHeight
        visible: expander.expanderVisible
        width: parent.width

        Rectangle {
            id: expandedBackground
            anchors {
                fill: parent
            }
            color: styleMusic.common.black
            opacity: 0.4
        }

        MouseArea {
            anchors {
                fill: parent
            }
            onClicked: mouse.accepted = true
        }

        // add to playlist
        Rectangle {
            id: playlistRow
            anchors {
                left: parent.left
                leftMargin: styleMusic.common.expandedLeftMargin
                top: parent.top
            }
            color: "transparent"
            height: parent.height
            visible: addToPlaylist
            width: units.gu(15)
            Icon {
                id: playlistTrack
                anchors.verticalCenter: parent.verticalCenter
                color: styleMusic.common.white
                name: "add"
                height: styleMusic.common.expandedItem
                width: styleMusic.common.expandedItem
            }
            Label {
                anchors {
                    left: playlistTrack.right
                    leftMargin: units.gu(0.5)
                    verticalCenter: parent.verticalCenter
                }
                color: styleMusic.common.white
                fontSize: "small"
                maximumLineCount: 3
                objectName: "addtoplaylist"
                text: i18n.tr("Add to playlist")
                width: parent.width - playlistTrack.width - units.gu(1)
                wrapMode: Text.WordWrap
            }
            MouseArea {
               anchors.fill: parent
               onClicked: {
                   expander.expanderVisible = false;
                   chosenElement = expander.model;
                   console.debug("Debug: Add track to playlist");
                   PopupUtils.open(Qt.resolvedUrl("../MusicaddtoPlaylist.qml"), mainView,
                   {
                       title: i18n.tr("Select playlist")
                   } )
               }
            }
        }
        // Queue
        Rectangle {
            id: queueRow
            anchors {
                left: playlistRow.left
                leftMargin: units.gu(15)
                top: parent.top
            }
            color: "transparent"
            height: parent.height
            visible: addToQueue
            width: units.gu(15)
            Image {
                id: queueTrack
                objectName: "queuetrack"
                anchors.verticalCenter: parent.verticalCenter
                source: "../images/queue.png"
                height: styleMusic.common.expandedItem
                width: styleMusic.common.expandedItem
            }
            Label {
                anchors {
                    left: queueTrack.right
                    leftMargin: units.gu(0.5)
                    verticalCenter: parent.verticalCenter
                }
                color: styleMusic.common.white
                fontSize: "small"
                width: parent.width - queueTrack.width - units.gu(1)
                text: i18n.tr("Add to queue")
                wrapMode: Text.WordWrap
                maximumLineCount: 3
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    expander.expanderVisible = false
                    console.debug("Debug: Add track to queue: " + expander.model)
                    trackQueue.append(expander.model)
                }
            }
        }

        // edit column
        Rectangle {
            id: editColumn
            anchors {
                left: parent.left
                leftMargin: styleMusic.common.expandedLeftMargin
                top: parent.top
            }
            color: "transparent"
            height: parent.height
            visible: editPlaylist
            width: units.gu(15)
            Icon {
                id: editPlaylistIcon
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                color: styleMusic.common.white
                name: "edit"
                height: styleMusic.common.expandedItem
                width: styleMusic.common.expandedItem
            }
            Label {
                anchors {
                    left: editPlaylistIcon.right
                    leftMargin: units.gu(0.5)
                    verticalCenter: parent.verticalCenter
                }
                color: styleMusic.common.white
                fontSize: "small"
                // TRANSLATORS: this refers to editing a playlist
                text: i18n.tr("Edit")
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    expander.expanderVisible = false;
                    customdebug("Edit playlist")
                    oldPlaylistName = expander.model.name
                    oldPlaylistID = expander.model.id
                    oldPlaylistIndex = expander.model.index
                    PopupUtils.open(editPlaylistDialog, mainView)
                }
            }
        }

        // delete column
        Rectangle {
            id: deleteColumn
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
            }
            color: "transparent"
            height: parent.height
            visible: deletePlaylist
            width: units.gu(15)
            Icon {
                id: deletePlaylistIcon
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                color: styleMusic.common.white
                name: "delete"
                height: styleMusic.common.expandedItem
                width: styleMusic.common.expandedItem
            }
            Label {
                anchors {
                    left: deletePlaylistIcon.right
                    leftMargin: units.gu(0.5)
                    verticalCenter: parent.verticalCenter
                }
                color: styleMusic.common.white
                fontSize: "small"
                // TRANSLATORS: this refers to deleting a playlist
                text: i18n.tr("Delete")
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    expander.expanderVisible = false;
                    customdebug("Delete")
                    oldPlaylistName = expander.model.name
                    oldPlaylistID = expander.model.id
                    oldPlaylistIndex = expander.model.index
                    PopupUtils.open(removePlaylistDialog, mainView)
                }
            }
        }
    }
}
