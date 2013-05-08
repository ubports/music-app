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
import Ubuntu.Components.ListItems 0.1

tools: ToolbarActions {

    // Share
    Action {
        objectName: "share"
        iconSource: Qt.resolvedUrl("images/share-app.png")
        text: i18n.tr("Share")
        onTriggered: {
            label.text = i18n.tr("Share pressed")
        }
    }

    // prevous track
    Action {
        objectName: "prev"
        iconSource: Qt.resolvedUrl("prev.png")
        text: i18n.tr("Previous")
        onTriggered: {
            label.text = i18n.tr("Prev track pressed")
        }
    }

    // Play or pause
    Action {
        objectName: "plaus"
        iconSource: Qt.resolvedUrl("prev.png")
        text: i18n.tr("Play")
        onTriggered: {
            label.text = i18n.tr("Play pressed")
            // should also change button to pause icon
        }
    }

    // Next track
    Action {
        objectName: "next"
        iconSource: Qt.resolvedUrl("next.png")
        text: i18n.tr("Next")
        onTriggered: {
            label.text = i18n.tr("Next track pressed")
        }
    }

    // Settings
    Action {
        objectName: "settings"
        iconSource: Qt.resolvedUrl("settings.png")
        text: i18n.tr("Settings")
        onTriggered: {
            print("Settings pressed")
            // show settings page
            pageStack.push(Qt.resolvedUrl("MusicSettings.qml")) // resolce pageStack issue
        }
    }
}
