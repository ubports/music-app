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

// Walkthrough - Slide 2
Component {
    id: slide2
    Item {
        id: slide2Container

        Column {
            id: mainColumn
            spacing: units.gu(4)
            anchors.fill: parent

            Label {
                id: introductionText
                text: i18n.tr("Listen to your music")
                font.bold: true
                fontSize: "x-large"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Image {
                id: centerImage
                height: parent.height - bodyText.contentHeight - introductionText.height - 4*mainColumn.spacing
                fillMode: Image.PreserveAspectFit
                anchors.horizontalCenter: parent.horizontalCenter
                source: Qt.resolvedUrl("../../images/music-app@30.png")
            }
            
            Label {
                id: bodyText
                width: parent.width
                wrapMode: Text.WordWrap
                font.pixelSize: units.dp(17)
                horizontalAlignment: Text.AlignHCenter
                text: i18n.tr("Add music by connecting your device to a computer and dragging files to the Music folder")
            }
        }
    }
}
