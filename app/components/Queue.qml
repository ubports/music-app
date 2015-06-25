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

import QtQuick 2.3
import QtQuick.LocalStorage 2.0
import Ubuntu.Components 1.1
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
    model: newPlayer.mediaPlayer.playlist
    objectName: "nowPlayingqueueList"

    property int normalHeight: units.gu(6)
    property int transitionDuration: 250  // transition length of animations

    onCountChanged: customdebug("Queue: Now has: " + queueList.count + " tracks")

    delegate: MusicListItem {
        id: queueListItem
        color: newPlayer.mediaPlayer.playlist.currentIndex === index ? "#2c2c34" : styleMusic.mainView.backgroundColor
        column: Column {
            property var metaModel: newPlayer.metaForSource(model.source)

            Label {
                id: trackTitle
                color: newPlayer.mediaPlayer.playlist.currentIndex === index ? UbuntuColors.blue : styleMusic.common.music
                fontSize: "small"
                objectName: "titleLabel"
                text: metaModel.title
            }

            Label {
                id: trackArtist
                color: styleMusic.common.subtitle
                fontSize: "x-small"
                objectName: "artistLabel"
                text: metaModel.author
            }
        }
        height: queueList.normalHeight
        objectName: "nowPlayingListItem" + index
        state: ""
        leftSideAction: Remove {
            onTriggered: newPlayer.mediaPlayer.playlist.removeSource(index)
        }
        multiselectable: true
        // reorderable: true  // FIXME: sort out reordering we need moveSource(from, to);
        rightSideActions: [
            AddToPlaylist{

            }
        ]

        onItemClicked: {
            customdebug("File: " + model.source) // debugger
            trackQueueClick(index);
        }
        onReorder: {
            console.debug("Move: ", from, to);

            // Our custom reorder component does -1 on the 'to' if the item is moved 'down'
            if (to > from) {
                to += 1;
            }

            // If the item has gone 'up' then the remove index needs to be +1
            // as a new item will be inserted before the item to be removed
            if (to <= from) {
                from += 1;
            }

            newPlayer.mediaPlayer.playlist.insertSource(to, model.source);
            newPlayer.mediaPlayer.playlist.removeSource(from);

            /*
            // Maintain currentIndex with current song
            if (from === newPlayer.mediaPlayer.playlist.currentIndex) {
                newPlayer.mediaPlayer.playlist.currentIndex = to;
            } else if (from < newPlayer.mediaPlayer.playlist.currentIndex && to >= newPlayer.mediaPlayer.playlist.currentIndex) {
                newPlayer.mediaPlayer.playlist.currentIndex -= 1;
            } else if (from > newPlayer.mediaPlayer.playlist.currentIndex && to <= newPlayer.mediaPlayer.playlist.currentIndex) {
                newPlayer.mediaPlayer.playlist.currentIndex += 1;
            }
            */
        }
    }
}
