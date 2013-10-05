/*
 * Copyright (C) 2013 Canonical Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Raúl Yeguas <neokore@gmail.com>
 *              Martin Borho <martin@borho.net>
 *              Andrew Starr-Bochicchio <a.starr.b@gmail.com>
 */
import QtQuick 2.0
import Ubuntu.Components 0.1

Item {
    id: refresh
    height: units.gu(5)
    width: units.gu(30)
    visible: false
    anchors {
        horizontalCenter: parent.horizontalCenter
        top: parent.top
        margins: units.gu(20)
    }
    ActivityIndicator {
        id: loading
        objectName: "LoadingSpinner"
        anchors.verticalCenter: parent.verticalCenter
        anchors.left:parent.left
        anchors.leftMargin: units.gu(5)
        running: refresh.visible
        z: 1
    }
    Label {
        text: i18n.tr("Loading...")
        anchors.verticalCenter: parent.verticalCenter
        fontSize: "large"
        anchors.left: loading.right
        anchors.leftMargin: units.gu(3)
    }
}
