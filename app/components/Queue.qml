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
import Ubuntu.Components 1.3
import "Delegates"
import "Flickables"
import "ListItemActions"
import "../logic/meta-database.js" as Library


MultiSelectListView {
    id: queueList
    anchors {
        fill: parent
    }
    autoModelMove: false  // ensures we use moveItem() not move() in onReorder
    footer: Item {
        height: mainView.height - (styleMusic.common.expandHeight + queueList.currentHeight) + units.gu(8)
    }
    model: player.mediaPlayer.playlist
    objectName: "nowPlayingqueueList"

    onCountChanged: customdebug("Queue: Now has: " + queueList.count + " tracks")

    delegate: MusicListItem {
        id: queueListItem
        color: player.mediaPlayer.playlist.currentIndex === index ? "#2c2c34" : styleMusic.mainView.backgroundColor
        column: Column {
            Label {
                id: trackTitle
                color: player.mediaPlayer.playlist.currentIndex === index ? UbuntuColors.blue : styleMusic.common.music
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
        leadingActions: ListItemActions {
            actions: [
                Remove {
                    onTriggered: player.mediaPlayer.playlist.removeItem(index)
                }
            ]
        }
        multiselectable: true
        objectName: "nowPlayingListItem" + index
        state: ""
        reorderable: true
        trailingActions: ListItemActions {
            actions: [
                AddToPlaylist {
                    modelOverride: metaModel  // model is not exposed with metadata so use metaModel
                }
            ]
            delegate: ActionDelegate {

            }
        }

        property var metaModel: player.metaForSource(model.source)

        onItemClicked: {
            customdebug("File: " + model.source) // debugger
            trackQueueClick(index);
        }
    }


    onReorder: {
        console.debug("Move: ", from, to);

        player.mediaPlayer.playlist.moveItem(from, to);
    }
}
