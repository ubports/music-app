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

Rectangle {
    id: editColumn
    color: "transparent"
    height: styleMusic.common.expandHeight
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
            parent.parent.parent.expanderLink.expanderVisible = false;
            customdebug("Edit playlist")
            oldPlaylistName = parent.parent.parent.expanderLink.model.name
            PopupUtils.open(editPlaylistDialog, mainView)
        }
    }
}
