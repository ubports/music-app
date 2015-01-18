/*
 * Copyright (C) 2014
 *      Nekhelesh Ramananthan <nik90@ubuntu.com>
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
 *
 * Upstream location:
 * https://github.com/krnekhelesh/flashback
 */

import QtQuick 2.3
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0 as ListItem

Page {
    id: walkthrough

    // Property to set the app name used in the walkthrough
    property string appName

    // Property to check if this is the first run or not
    property bool isFirstRun: true

    // Property to store the slides shown in the walkthrough (Each slide is a component defined in a separate file for simplicity)
    property list<Component> model

    // Property to signal walkthrough completion
    signal finished

    // ListView to show the slides
    ListView {
        id: listView
        anchors {
            left: parent.left
            right: parent.right
            top: skipLabel.bottom
            bottom: separator.top
        }

        model: walkthrough.model
        snapMode: ListView.SnapOneItem
        orientation: Qt.Horizontal
        highlightMoveDuration: UbuntuAnimation.FastDuration
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightFollowsCurrentItem: true

        delegate: Item {
            width: listView.width
            height: listView.height
            clip: true

            Loader {
                anchors {
                    fill: parent
                    margins: units.gu(2)
                }

                sourceComponent: modelData
            }
        }
    }

    // Label to skip the walkthrough. Only visible on the first slide
    Label {
        id: skipLabel

        color: "grey"
        fontSize: "small"
        width: contentWidth
        text: listView.currentIndex === 0 ? i18n.tr("Already used %1? <b>Skip the tutorial</b>").arg(appName) : i18n.tr("Skip")

        anchors {
            top: parent.top
            left: parent.left
            margins: units.gu(2)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: walkthrough.finished()
        }
    }

    // Separator between walkthrough slides and slide indicator
    ListItem.ThinDivider {
        id: separator
        anchors.bottom: slideIndicator.top
    }

    // Indicator element to represent the current slide of the walkthrough
    Row {
        id: slideIndicator
        height: units.gu(6)
        spacing: units.gu(2)
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }

        Repeater {
            model: walkthrough.model.length
            delegate: Rectangle {
                height: width
                radius: width/2
                width: units.gu(2)
                antialiasing: true
                anchors.verticalCenter: parent.verticalCenter
                color: listView.currentIndex >= index ? "green" : "white"
                Behavior on color {
                    ColorAnimation {
                        duration: UbuntuAnimation.FastDuration
                    }
                }
            }
        }
    }
}
