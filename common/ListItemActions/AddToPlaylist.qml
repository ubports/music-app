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

import QtQuick 2.3
import Ubuntu.Components 1.1

Action {
    iconName: "add-to-playlist"
    objectName: "addToPlaylistAction"
    text: i18n.tr("Add to playlist")

    property bool primed: false

    onTriggered: {
       chosenElements = [makeDict(model)];
       console.debug("Debug: Add track to playlist");

        var comp = Qt.createComponent("../../MusicaddtoPlaylist.qml")
        var addToPlaylist = comp.createObject(mainPageStack, {});

        if (addToPlaylist === null) {  // Error Handling
            console.log("Error creating object");
        }

       mainPageStack.push(addToPlaylist)
    }
}
