/*
 * Copyleft Daniel Holm.
 *
 * Authors:
 *  Daniel Holm <d.holmen@gmail.com>
 *  Victor Thompson <victor.thompson@gmail.com>
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
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Components.Popups 0.1
import QtQuick.LocalStorage 2.0
import "settings.js" as Settings

Dialog {
    id: root
    title: i18n.tr("First Run")
    text: i18n.tr("This appears to be your first run. Please set your music directory.")

    Row {
        spacing: units.gu(2)
        TextField {
            id: musicDirField
            placeholderText: "/home/username/Music"
            hasClearButton: false
            text: musicDir
        }
    }

    Button {
        text: i18n.tr("Save")
        color: "green"
        onClicked: {
            PopupUtils.close(root)
            // set new music dir
            Settings.initialize()
            Settings.setSetting("currentfolder", musicDirField.text)
            console.debug("Debug: Set new music dir to: "+musicDirField.text)
        }
    }
}
