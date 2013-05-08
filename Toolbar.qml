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
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Components.Popups 0.1

Component {
    // Share
    Action {
        id: shareTrack
        objectName: "share"

        iconSource: Qt.resolvedUrl("images/icon_share@20.png")
        text: i18n.tr("Share")

        onTriggered: {
            console.debug('Debug: Share pressed')
        }
    }

    // prevous track
    Action {
        id: prevTrack
        objectName: "prev"

        iconSource: Qt.resolvedUrl("images/prev.png")
        text: i18n.tr("Previous")

        onTriggered: {
            console.debug('Debug: Prev track pressed')
        }
    }

    // Play
    Action {
        id: playTrack
        objectName: "play"

        iconSource: Qt.resolvedUrl("images/icon_play@20.png")
        text: i18n.tr("Play")

        onTriggered: {
            //trackStatus: 'pause' // this changes on press
            onTrackStatusChange(playTrack.text)
        }
    }

    // Next track
    Action {
        id: nextTrack
        objectName: "next"

        iconSource: Qt.resolvedUrl("images/next.png")
        text: i18n.tr("Next")

        onTriggered: {
            console.debug('Debug: next track pressed')
        }
    }

    // Queue
    Action {
        id: trackQueue
        objectName: "queuelist"
        iconSource: Qt.resolvedUrl("images/icon_settings@20.png")
        text: i18n.tr("Queue")
        onTriggered: {
            PopupUtils.open(queueDialog, trackQueue)
        }
    }

    // Settings
    Action {
        objectName: "settings"

        iconSource: Qt.resolvedUrl("images/icon_settings@20.png")
        text: i18n.tr("Settings")

        onTriggered: {
            console.debug('Debug: Settings pressed')
            // show settings page
            //page: MusicSettings { id: musicSettings }
        }
    }
}
