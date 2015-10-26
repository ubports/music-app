/*
 * Copyright (C) 2015
 *      Andrew Hayzen <ahayzen@gmail.com>
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

import QtMultimedia 5.4
import QtQuick 2.4
import Qt.labs.settings 1.0

Item {
    objectName: "player"

    property var currentMeta: ({})
    property alias mediaPlayer: mediaPlayer
    property alias repeat: settings.repeat
    property alias shuffle: settings.shuffle

    function metaForSource(source) {
        var blankMeta = {
            album: "",
            art: "",
            author: "",
            filename: "",
            title: ""
        };

        source = source.toString();

        if (source.indexOf("file://") === 0) {
            source = source.substring(7);
        }

        return musicStore.lookup(decodeFileURI(source)) || blankMeta;
    }

    Settings {
        id: settings
        category: "PlayerSettings"

        property bool repeat: true
        property bool shuffle: false
    }

    // https://code.launchpad.net/~phablet-team/kubuntu-packaging/qtmultimedia-opensource-src-playlist-support/+merge/262229
    MediaPlayer {
        id: mediaPlayer
        playlist: Playlist {
            id: mediaPlayerPlaylist
            playbackMode: {  // FIXME: doesn't see to work
                if (settings.shuffle) {
                    Playlist.Random
                } else if (settings.repeat) {
                    Playlist.Loop
                } else {
                    Playlist.Sequential
                }
            }

            onCurrentSourceChanged: currentMeta = metaForSource(currentSource)
            onMediaChanged: {
                saveQueue()

                // FIXME: shouldn't be needed? seems to be a bug where when appending currentSourceChanged is not emitted
                //if (start === currentIndex) {
                //    currentMeta = metaForSource(currentSource)
                //}
            }
            onMediaInserted: {
                // When add to queue is done on an empty list currentIndex needs to be set
                if (start === 0 && currentIndex === -1) {
                    currentIndex = 0;
                }

                saveQueue()

                // FIXME: shouldn't be needed? seems to be a bug where when appending currentSourceChanged is not emitted
                if (start === currentIndex) {
                    currentMeta = metaForSource(currentSource)
                }
            }
            onMediaRemoved: {
                saveQueue()

                // FIXME: shouldn't be needed? seems to be a bug where when appending currentSourceChanged is not emitted
                if (start === currentIndex) {
                    currentMeta = metaForSource(currentSource)
                }
            }

            // TODO: AP needs queue length

            function addSourcesFromModel(model) {
                var sources = []

                for (var i=0; i < model.rowCount; i++) {
                    sources.push(Qt.resolvedUrl(model.get(i, model.RoleModelData).filename));
                }

                addSources(sources);
            }

            function removeSources(items) {
                items.sort();

                for (var i=0; i < items.length; i++) {
                    removeSource(items[i] - i);
                }
            }

            function saveQueue(start, end) {
                // TODO: should not be hardcoded
                // FIXME: doesn't work
                // FIXME: disabled for now to not cause errors/slow down
                // save("/home/phablet/.local/share/com.ubuntu.music/queue.m3u");
            }
        }

        // FIXME: Bind to settings.repeat/shuffle instead of playbackMode
        // as that doesn't emit changes
        property bool canGoPrevious: {
            playlist.currentIndex !== 0 ||
            settings.repeat ||
            settings.shuffle
        }
        property bool canGoNext: {
            playlist.currentIndex !== (playlist.mediaCount - 1) ||
            settings.repeat ||
            settings.shuffle
        }

        property double progress: 0

        onDurationChanged: _calcProgress()
        onPositionChanged: _calcProgress()

        onStatusChanged: {
            if (status == MediaPlayer.EndOfMedia) {
                console.debug("End of media, stopping.")
                playlist.currentIndex = 0;
                stop();

                _calcProgress();  // ensures progress bar has reset
            }
        }

        onStopped: {  // hit when pressing next() on last track with repeat off
            console.debug("onStopped.")
            stop();
            playlist.currentIndex = 0;
            stop();

            _calcProgress();  // ensures progress bar has reset
        }

        function _calcProgress() {
            if (duration > 0) {
                progress = position / duration;
            } else if (position >= duration) {
                progress = 0;
            } else {
                progress = 0;
            }
        }

        function toggle() {
            if (playbackState === MediaPlayer.PlayingState) {
                pause();
            } else {
                play();
            }
        }
    }
}
