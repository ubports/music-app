/*
 * Copyright (C) 2013, 2014
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
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import Qt.labs.settings 1.0

/*
 * This file should *only* manage the media playing and the relevant settings
 * It should therefore only access MediaPlayer, trackQueue and Settings
 * Anything else within the app should use Connections to listen for changes
 */


Item {
    objectName: "player"

    property string currentMetaAlbum: ""
    property string currentMetaArt: ""
    property string currentMetaArtist: ""
    property string currentMetaFile: ""
    property string currentMetaTitle: ""
    property int currentIndex: -1
    property int duration: 1
    readonly property bool isPlaying: player.playbackState === MediaPlayer.PlayingState
    readonly property var playbackState: mediaPlayerLoader.status == Loader.Ready ? mediaPlayerLoader.item.playbackState : MediaPlayer.StoppedState
    property int position: 0
    property alias repeat: settings.repeat
    property alias shuffle: settings.shuffle
    readonly property string source: mediaPlayerLoader.status == Loader.Ready ? mediaPlayerLoader.item.source : ""
    readonly property double volume: mediaPlayerLoader.status == Loader.Ready ? mediaPlayerLoader.item.volume : 1.0

    signal stopped()

    Settings {
        id: settings
        category: "PlayerSettings"

        property bool repeat: true
        property bool shuffle: false
    }

    Connections {
        target: trackQueue.model
        onCountChanged: {
            if (trackQueue.model.count === 1) {
                player.currentIndex = 0;
                setSource(Qt.resolvedUrl(trackQueue.model.get(0).filename))
            } else if (trackQueue.model.count === 0) {
                player.currentIndex = -1
                setSource("")
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

        // Do not shuffle if repeat is off and there is only one track in the queue
        if (shuffle && !(trackQueue.model.count === 1 && !repeat)) {
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
            } else if(direction === 1 && (repeat || fromControls)) {
                newIndex = 0
            } else if(direction === -1 && (repeat || fromControls)) {
                newIndex = trackQueue.model.count - 1
            }
            else
            {
                player.stop()
                return;
            }
        }

        if (startPlaying) {  // only start the track if told
            playSong(trackQueue.model.get(newIndex).filename, newIndex)
        }
        else {
            currentIndex = newIndex
            setSource(Qt.resolvedUrl(trackQueue.model.get(newIndex).filename))
        }

        // Set index into queue
        queueIndex = currentIndex
    }

    function nextSong(startPlaying, fromControls) {
        getSong(1, startPlaying, fromControls)
    }

    function pause() {
        mediaPlayerLoader.item.pause();
    }

    function play() {
        mediaPlayerLoader.item.play();
    }

    function playSong(filepath, index) {
        stop();
        currentIndex = index;
        queueIndex = index;
        setSource(filepath);
        play();
    }

    function previousSong(startPlaying) {
        getSong(-1, startPlaying)
    }

    function seek(position) {
        mediaPlayerLoader.item.seek(position);
    }

    function setSource(filepath) {
        mediaPlayerLoader.item.source = Qt.resolvedUrl(filepath);
    }

    function setVolume(volume) {
        mediaPlayerLoader.item.volume = volume
    }

    function stop() {
        mediaPlayerLoader.item.stop();
    }

    function toggle() {
        if (player.playbackState == MediaPlayer.PlayingState) {
            pause()
        }
        else {
            play()
        }
    }

    Loader {
        id: mediaPlayerLoader
        asynchronous: true
        sourceComponent: Component {
            MediaPlayer {
                muted: false

                onDurationChanged: player.duration = duration
                onPositionChanged: player.position = position

                onSourceChanged: {
                    // Force invalid source to ""
                    if (source === undefined || source === false) {
                        source = ""
                        return
                    }

                    if (source.toString() === "") {
                        player.currentIndex = -1
                        player.stop()
                    }
                    else {
                        var obj = trackQueue.model.get(player.currentIndex);
                        player.currentMetaAlbum = obj.album;

                        if (obj.art !== undefined) {  // FIXME: protect against no art property in playlists
                            player.currentMetaArt = obj.art;
                        }

                        player.currentMetaArtist = obj.author;
                        player.currentMetaFile = obj.filename;
                        player.currentMetaTitle = obj.title;
                    }

                    console.log("Source: " + source.toString())
                    console.log("Index: " + player.currentIndex)
                }

                onStatusChanged: {
                    if (status == MediaPlayer.EndOfMedia) {
                        nextSong(true, false) // next track
                    }
                }

                onStopped: player.stopped()
            }
        }
    }
}

