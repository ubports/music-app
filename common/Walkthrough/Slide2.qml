/*
 * Copyright (C) 2014-2015
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
            anchors.fill: parent
            spacing: units.gu(4)

            Image {
                id: centerImage
                anchors {
                    top: parent.top
                    topMargin: units.gu(6)
                    horizontalCenter: parent.horizontalCenter
                }
                height: (parent.height - bodyText.contentHeight - introductionText.height - 4*mainColumn.spacing)/2
                fillMode: Image.PreserveAspectFit
                source: Qt.resolvedUrl("../../images/sd_phone_icon@27.png")
            }

            Label {
                id: introductionText
                anchors {
                    bottom: bodyText.top
                    bottomMargin: mainColumn.spacing
                }
                fontSize: "x-large"
                horizontalAlignment: Text.AlignHLeft
                text: i18n.tr("Import your music")
            }
            
            Label {
                id: bodyText
                anchors {
                    bottom: parent.bottom
                    bottomMargin: units.gu(10)
                }
                fontSize: "large"
                horizontalAlignment: Text.AlignHLeft
                text: i18n.tr("Plug your phone into your Ubuntu computer and drag and drop files staight across.")
                width: parent.width
                wrapMode: Text.WordWrap
            }
        }
    }
}
