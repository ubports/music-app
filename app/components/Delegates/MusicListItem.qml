/*
 * Copyright (C) 2013, 2014, 2015, 2016
 *      Andrew Hayzen <ahayzen@gmail.com>
 *      Nekhelesh Ramananthan <krnekhelesh@gmail.com>
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
import "../"

ListItem {
    color: styleMusic.mainView.backgroundColor
    height: listItemLayout.height
    highlightColor: Qt.lighter(color, 1.2)

    // Store the currentColor so that actions can bind to it
    property var currentColor: highlighted ? highlightColor : color

    property alias imageSource: image.imageSource

    property bool multiselectable: false
    property bool reorderable: false

    property alias subtitle: listItemLayout.subtitle
    property alias title: listItemLayout.title

    signal itemClicked()

    onClicked: {
        if (selectMode) {
            selected = !selected;
        } else {
            itemClicked()
        }
    }

    onPressAndHold: {
        if (reorderable) {
            ListView.view.ViewItems.dragMode = !ListView.view.ViewItems.dragMode
        }

        if (multiselectable) {
            ListView.view.ViewItems.selectMode = !ListView.view.ViewItems.selectMode
        }
    }

    divider {
        visible: false
    }

    ListItemLayout {
        id: listItemLayout

        padding.bottom: image.visible ? units.gu(.5) : units.gu(1.5)
        padding.top: image.visible ? units.gu(.5) : units.gu(1.5)

        subtitle.color: styleMusic.common.subtitle
        subtitle.fontSize: "x-small"
        subtitle.wrapMode: Text.WrapAnywhere

        title.color: styleMusic.common.music
        title.fontSize: "small"
        title.wrapMode: Text.WrapAnywhere

        Image {
            id: image
            anchors {
                verticalCenter: parent.verticalCenter
            }
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            height: width
            SlotsLayout.position: SlotsLayout.Leading
            source: {
                if (imageSource !== undefined && imageSource !== "") {
                    if (imageSource.art !== undefined) {
                        imageSource.art
                    } else {
                        "image://albumart/artist=" + imageSource.author + "&album=" + imageSource.album
                    }
                } else {
                    ""
                }
            }
            sourceSize.height: height
            sourceSize.width: width
            width: units.gu(6)
            visible: imageSource !== undefined

            onStatusChanged: {
                if (status === Image.Error) {
                    source = Qt.resolvedUrl("../../graphics/music-app-cover@30.png")
                }
            }

            property var imageSource
        }
    }
}
