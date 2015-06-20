/*
 * Copyright (C) 2013, 2014, 2015
 *      Andrew Hayzen <ahayzen@gmail.com>
 *      Daniel Holm <d.holmen@gmail.com>
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
 */

import QtQuick 2.4
import QtQuick.LocalStorage 2.0
import Ubuntu.Components 1.2
import "Delegates"
import "Flickables"
import "ListItemActions"
import "../logic/meta-database.js" as Library


MultiSelectListView {
    id: queueList
    anchors {
        fill: parent
    }
    footer: Item {
        height: mainView.height - (styleMusic.common.expandHeight + queueList.currentHeight) + units.gu(8)
    }
    model: trackQueue.model
    objectName: "nowPlayingqueueList"

    property int normalHeight: units.gu(6)
    property int transitionDuration: 250  // transition length of animations

    onCountChanged: customdebug("Queue: Now has: " + queueList.count + " tracks")

    delegate: MusicListItem {
        id: queueListItem
        color: player.currentIndex === index ? "#2c2c34" : styleMusic.mainView.backgroundColor
        column: Column {
            Label {
                id: trackTitle
                color: player.currentIndex === index ? UbuntuColors.blue : styleMusic.common.music
                fontSize: "small"
                objectName: "titleLabel"
                text: model.title
            }

            Label {
                id: trackArtist
                color: styleMusic.common.subtitle
                fontSize: "x-small"
                objectName: "artistLabel"
                text: model.author
            }
        }
        height: queueList.normalHeight
        objectName: "nowPlayingListItem" + index
        state: ""
        leftSideAction: Remove {
            onTriggered: trackQueue.removeQueueList([index])
        }
        multiselectable: true
        reorderable: true
        rightSideActions: [
            AddToPlaylist{

            }
        ]

        onItemClicked: {
            customdebug("File: " + model.filename) // debugger
            trackQueueClick(index);  // toggle track state
        }
        onReorder: {
            console.debug("Move: ", from, to);

            trackQueue.model.move(from, to, 1);
            Library.moveQueueItem(from, to);

            // Maintain currentIndex with current song
            if (from === player.currentIndex) {
                player.currentIndex = to;
            }
            else if (from < player.currentIndex && to >= player.currentIndex) {
                player.currentIndex -= 1;
            }
            else if (from > player.currentIndex && to <= player.currentIndex) {
                player.currentIndex += 1;
            }

            queueIndex = player.currentIndex
        }
    }
}
