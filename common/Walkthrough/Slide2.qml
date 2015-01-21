/*
 * Copyright (C) 2014-2015
 *      Andrew Hayzen <ahayzen@gmail.com>
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
    Column {
        id: slide2Container
        anchors {
            fill: parent
        }
        spacing: units.gu(4)

        Item {
            height: units.gu(2)
            width: parent.width
        }

        Image {
            id: centerImage
            anchors {
                horizontalCenter: parent.horizontalCenter
            }
            height: (parent.height - bodyText.contentHeight - introductionText.height - 4*units.gu(4))/2
            fillMode: Image.PreserveAspectFit
            source: Qt.resolvedUrl("../../images/sd_phone_icon.png")
        }

        Label {
            id: introductionText
            fontSize: "x-large"
            horizontalAlignment: Text.AlignHLeft
            text: i18n.tr("Import your music")
            width: parent.width
        }

        Label {
            id: bodyText
            fontSize: "large"
            horizontalAlignment: Text.AlignHLeft
            text: i18n.tr("Connect your device to any computer and simply drag files to the Music folder or insert removable media with music.")
            width: parent.width
            wrapMode: Text.WordWrap
        }

        Item {
            height: units.gu(6)
            width: parent.width
        }
    }
}
