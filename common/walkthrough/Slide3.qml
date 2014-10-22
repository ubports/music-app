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

// Walkthrough - Slide 7
Component {
    id: slide7
    Item {
        id: slide7Container

        Column {
            id: mainColumn

            spacing: units.gu(4)
            anchors.fill: parent

            Label {
                id: introductionText
                fontSize: "x-large"
                font.bold: true
                text: i18n.tr("Discover new music")
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Image {
                id: smileImage
                height: parent.height - introductionText.height - finalMessage.contentHeight - 4.5*mainColumn.spacing
                fillMode: Image.PreserveAspectFit
                source: Qt.resolvedUrl("../../images/music-app@30.png")
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                id: finalMessage
                text: i18n.tr("Or import music from the web or an online store to discover something new")
                width: parent.width
                wrapMode: Text.WordWrap
                font.pixelSize: units.dp(17)
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Button {
                id: continueButton
                color: UbuntuColors.green
                height: units.gu(5)
                width: units.gu(25)
                text: i18n.tr("Start using Music!")
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: finished()
            }
        }
    }
}
