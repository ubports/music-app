/*
 * Copyleft Daniel Holm.
 *
 * Authors:
 *  Daniel Holm <d.holmen@gmail.com>
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
import Ubuntu.Components.ListItems 0.1 as ListItem


Dialog {
    id: queueDialog

    ListView {
        id: queueList
        width: units.gu(40)
        height: units.gu(50)
        model: trackQueue
        delegate: ListItem.Standard {
            //text: artist+" - "+title
            text: file
            removable: true
            onClicked: {
                console.debug("Debug: Play "+file+" instead - now.")
                playMusic.source = musicDir+file
                playMusic.play()
                trackQueue.remove(index)
            }
            onItemRemoved: {
                trackQueue.remove(index)
            }
        }
    }

    // Clean whole queue button
    Button {
        text: i18n.tr("Clear")
        onClicked: {
            console.debug("Debug: Track queue cleared.")
            trackQueue.clear()
        }
    }

    // close dialog button
    Button {
        text: i18n.tr("Close")
        onClicked: {
            PopupUtils.close(queueDialog)
        }
    }
}
