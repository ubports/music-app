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

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.Popups 0.1

Item {
    id: expander
    property int actualListItemHeight: -1
    property alias backgroundOpacity: expandedBackground.opacity
    property bool buttonEnabled: true
    property int expanderButtonCentreFromBottom: -1
    property alias expanderButtonWidth: expandableButton.width
    property var listItem: null
    property var model: null
    property alias row: expanderRowLoader.sourceComponent
    property bool expanderVisible: false
    property bool _heightChangeLock: false

    Component.onCompleted: {
        if (listItem !== null && actualListItemHeight === -1) {
            actualListItemHeight = listItem.height;
        }
        if (listItem !== null && expanderButtonCentreFromBottom === -1) {
            expanderButtonCentreFromBottom = listItem.height / 2;
        }

        collapseExpand.connect(onCollapseExpand);
    }

    function onCollapseExpand(indexCol)
    {
        if (expander !== undefined && expander.expanderVisible) {
            customdebug("auto collapse")
            expander.expanderVisible = false;
        }
    }

    Connections {
        target: listItem
        onHeightChanged: {
            if (!expander._heightChangeLock && expander.expanderVisible) {
                expander._heightChangeLock = true;
                listItem.height += styleMusic.common.expandHeight;
                expander._heightChangeLock = false;
            }
        }
    }

    onExpanderVisibleChanged: {
        expander._heightChangeLock = true;
        if (expanderVisible) {
            listItem.height += styleMusic.common.expandHeight;
        }
        else {
            listItem.height -= styleMusic.common.expandHeight;
        }
        expander._heightChangeLock = false;
    }

    Rectangle {
        id: expandableButton
        anchors {
            bottom: parent.bottom
            bottomMargin: expanderVisible ? expandedContainer.height : undefined
            right: parent.right
        }
        color: "transparent"
        height: expanderButtonCentreFromBottom * 2
        width: expandableButtonImage.width * 2

        Image {
            id: expandableButtonImage
            anchors {
                left: parent.left
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
                horizontalCenter: parent.horizontalCenter
                top: parent.top
            }
            height: parent.height
            width: parent.width + units.gu(1)
            onClicked: {
                if (!expander.buttonEnabled) {
                    return;
                }

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
            topMargin: actualListItemHeight
        }
        color: "transparent"
        height: styleMusic.common.expandHeight
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

        Rectangle {
            anchors {
                fill: parent
                leftMargin: styleMusic.common.expandedLeftMargin
            }
            color: "transparent"
            Loader {
                id: expanderRowLoader
                anchors {
                    verticalCenter: parent.verticalCenter
                }
                property alias expanderLink: expander
            }
        }

    }
}
