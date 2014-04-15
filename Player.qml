/*
 * Copyright (C) 2013 Andrew Hayzen <ahayzen@gmail.com>
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
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import "settings.js" as Settings

/*
 * This file should *only* manage the media playing and the relevant settings
 * It should therefore only access MediaPlayer, trackQueue and Settings
 * Anything else within the app should use Connections to listen for changes
 */


Item {
    objectName: "player"

    property string currentMetaAlbum: ""
    property string currentMetaArtist: ""
    property string currentMetaCover: ""
    property string currentMetaFile: ""
    property string currentMetaTitle: ""
    property int currentIndex: -1
    property alias duration: mediaPlayer.duration
    property bool isPlaying: player.playbackState === MediaPlayer.PlayingState
    property alias playbackState: mediaPlayer.playbackState
    property alias position: mediaPlayer.position
    property bool repeat: Settings.getSetting("repeat") === "1"
    property bool shuffle: Settings.getSetting("shuffle") === "1"
    property alias source: mediaPlayer.source
    property alias volume: mediaPlayer.volume

    onRepeatChanged: {
        Settings.setSetting("repeat", repeat ? "1" : "0")
        console.debug("Repeat:", Settings.getSetting("repeat") === "1")
    }

    onShuffleChanged: {
        Settings.setSetting("shuffle", shuffle ? "1" : "0")
        console.debug("Shuffle:", Settings.getSetting("shuffle") === "1")
    }

    Connections {
        target: trackQueue.model
        onCountChanged: {
            if (trackQueue.model.count === 1) {
                player.currentIndex = 0;
                player.source = Qt.resolvedUrl(trackQueue.model.get(0).file)
            } else if (trackQueue.model.count === 0) {
                player.currentMetaCover = ""
            }
        }
    }

    function getSong(direction, startPlaying, fromControls) {
        // Seek to start if threshold reached when selecting previous
        if (direction === -1 && (player.position / 1000) > 5)
        {
            player.seek(0);  // seek to start
            return;
        }

        if (trackQueue.model.count == 0)
        {
            customdebug("No tracks in queue.");
            return;
        }

        // default fromControls and startPlaying to true
        fromControls = fromControls === undefined ? true : fromControls;
        startPlaying = startPlaying === undefined ? true : startPlaying;
        var newIndex;

        console.log("currentIndex: " + currentIndex)
        console.log("trackQueue.count: " + trackQueue.model.count)

        if (shuffle) {
            var now = new Date();
            var seed = now.getSeconds();

            // trackQueue must be above 1 otherwise an infinite loop will occur
            do {
                newIndex = (Math.floor((trackQueue.model.count)
                                       * Math.random(seed)));
            } while (newIndex === currentIndex && trackQueue.model.count > 1)
        } else {
            if ((currentIndex < trackQueue.model.count - 1 && direction === 1 )
                    || (currentIndex > 0 && direction === -1)) {
                newIndex = currentIndex + direction
            } else if(direction === 1 && (Settings.getSetting("repeat") === "1"
                                          || fromControls)) {
                newIndex = 0
            } else if(direction === -1 && (Settings.getSetting("repeat") === "1" || fromControls)) {
                newIndex = trackQueue.model.count - 1
            }
            else
            {
                player.stop()
                return;
            }
        }

        if (startPlaying) {  // only start the track if told
            playSong(trackQueue.model.get(newIndex).file, newIndex)
        }
        else {
            currentIndex = newIndex
            source = Qt.resolvedUrl(trackQueue.model.get(newIndex).file)
        }

        // Always jump to current track
        nowPlaying.jumpToCurrent(true, nowPlaying, musicToolbar.currentTab)
    }

    function nextSong(startPlaying, fromControls) {
        getSong(1, startPlaying, fromControls)
    }

    function pause() {
        mediaPlayer.pause();
    }

    function play() {
        mediaPlayer.play();
    }

    function playSong(filepath, index) {
        player.stop();
        currentIndex = index;
        player.source = Qt.resolvedUrl(filepath);
        player.play();
    }

    function previousSong(startPlaying) {
        getSong(-1, startPlaying)
    }

    function seek(position) {
        mediaPlayer.seek(position);
    }

    function stop() {
        mediaPlayer.stop();
    }

    function toggle() {
        if (player.playbackState == MediaPlayer.PlayingState) {
            player.pause()
        }
        else {
            player.play()
        }
    }

    MediaPlayer {
        id: mediaPlayer
        muted: false

        onSourceChanged: {
            // Force invalid source to ""
            if (source === undefined || source === false) {
                source = ""
                return
            }

            if (source === "") {
                currentIndex = -1
                player.stop()
            }
            else {
                var obj = trackQueue.model.get(player.currentIndex);
                currentMetaAlbum = obj.album;
                currentMetaArtist = obj.artist;
                currentMetaCover = obj.cover;
                currentMetaFile = obj.file;
                currentMetaTitle = obj.title;
            }

            console.log("Source: " + source.toString())
            console.log("Index: " + currentIndex)
        }

        onStatusChanged: {
            if (status == MediaPlayer.EndOfMedia) {
                nextSong(true, false) // next track
            }
        }
    }
}

