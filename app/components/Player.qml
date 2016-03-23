/*
 * Copyright (C) 2015, 2016
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

import QtMultimedia 5.6
import QtQuick 2.4
import Qt.labs.settings 1.0

import QtQuick.LocalStorage 2.0
import "../logic/meta-database.js" as Library

Item {
    objectName: "player"

    // For autopilot as we can't access the MediaPlayer object pad.lv/1269578
    readonly property bool isPlaying: mediaPlayerObject.playbackState === MediaPlayer.PlayingState
    readonly property alias count: mediaPlayerPlaylist.itemCount
    readonly property alias currentIndex: mediaPlayerPlaylist.currentIndex
    readonly property alias currentItemSource: mediaPlayerPlaylist.currentItemSource
    readonly property alias position: mediaPlayerObject.position

    // FIXME: pad.lv/1269578 use Item as autopilot cannot 'see' a var/QtObject
    property alias currentMeta: currentMetaItem

    property alias mediaPlayer: mediaPlayerObject
    property alias repeat: settings.repeat
    property alias shuffle: settings.shuffle

    Item {
        id: currentMetaItem
        objectName: "currentMeta"

        property string album: ""
        property string art: ""
        property string author: ""
        property string filename: ""
        property string title: ""
        property bool useFallbackArt: false
    }

    // Return the metadata for the source given from mediascanner2
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

    MediaPlayer {
        id: mediaPlayerObject
        playlist: Playlist {
            id: mediaPlayerPlaylist
            playbackMode: {
                if (settings.shuffle) {
                    Playlist.Random
                } else if (settings.repeat) {
                    Playlist.Loop
                } else {
                    Playlist.Sequential
                }
            }

            // as that doesn't emit changes
            readonly property bool canGoPrevious: {  // FIXME: pad.lv/1517580 use previousIndex() > -1 after mh implements it
                currentIndex !== 0 ||
                settings.repeat ||
                settings.shuffle ||  // FIXME: pad.lv/1517580 no way to know when we are at the end of a shuffle yet
                mediaPlayerObject.position > 5000
            }
            readonly property bool canGoNext: {  // FIXME: pad.lv/1517580 use nextIndex() > -1 after mh implements it
                currentIndex !== (itemCount - 1) ||
                settings.repeat ||
                settings.shuffle  // FIXME: pad.lv/1517580 no way to know when we are at the end of a shuffle yet
            }
            readonly property int count: itemCount  // header actions etc depend on the model having 'count'
            readonly property bool empty: itemCount === 0
            property int pendingCurrentIndex: -1
            property var pendingCurrentState: null
            property int pendingShuffle: -1

            onCurrentItemSourceChanged: {
                var meta = metaForSource(currentItemSource);

                currentMeta.album = meta.album;
                currentMeta.art = meta.art;
                currentMeta.author = meta.author;
                currentMeta.filename = meta.filename;
                currentMeta.title = meta.title;
                currentMeta.useFallbackArt = false;

                mediaPlayerObject._calcProgress();
            }
            onItemChanged: {
                console.debug("*** Saving play queue in onItemChanged");
                saveQueue()
            }
            onItemInserted: {
                // When add to queue is done on an empty list currentIndex needs to be set
                if (start === 0 && currentIndex === -1 && pendingCurrentIndex < 1 && pendingShuffle === -1) {
                    currentIndex = 0;

                    pendingCurrentIndex = -1;
                    processPendingCurrentState();
                }

                // Check if the pendingCurrentIndex is now valid
                if (pendingCurrentIndex !== -1 && pendingCurrentIndex < itemCount) {
                    currentIndex = pendingCurrentIndex;

                    pendingCurrentIndex = -1;
                    processPendingCurrentState();
                }

                // Check if there is pending shuffle
                // pendingShuffle holds the expected size of the model
                if (pendingShuffle > -1 && pendingShuffle <= itemCount) {
                    pendingShuffle = -1;

                    nextWrapper();  // find a random track
                    mediaPlayerObject.play();  // next does not enforce play
                }

                console.debug("*** Saving play queue in onItemInserted");
                saveQueue()
            }
            onItemRemoved: {
                console.debug("*** Saving play queue in onItemRemoved");
                saveQueue()
            }

            function addItemsFromModel(model) {
                var items = []

                // TODO: remove once playlists uses U1DB
                if (model.hasOwnProperty("linkLibraryListModel")) {
                    model = model.linkLibraryListModel;
                }

                for (var i=0; i < model.rowCount; i++) {
                    items.push(Qt.resolvedUrl(model.get(i, model.RoleModelData).filename));
                }

                addItems(items);
            }

            // Wrap the clear() method because we need to call stop first
            function clearWrapper() {
                // Stop the current playback (this ensures that play is run later)
                if (mediaPlayerObject.playbackState === MediaPlayer.PlayingState) {
                    mediaPlayerObject.stop();
                }

                clear();
            }

            // Replicates a model.get() on a ms2 model
            function get(index, role) {
                return metaForSource(itemSource(index));
            }

            // Wrap the next() method so we can check canGoNext
            function nextWrapper() {
                if (canGoNext) {
                    next();
                }
            }

            // Wrap the previous() method so we can check canGoPrevious
            function previousWrapper() {
                if (canGoPrevious) {
                    previous();
                }
            }

            // Process the pending current PlaybackState
            function processPendingCurrentState() {
                if (pendingCurrentState === MediaPlayer.PlayingState) {
                    console.debug("Loading pending state play()");
                    mediaPlayerObject.play();
                } else if (pendingCurrentState === MediaPlayer.PausedState) {
                    console.debug("Loading pending state pause()");
                    mediaPlayerObject.pause();
                } else if (pendingCurrentState === MediaPlayer.StoppedState) {
                    console.debug("Loading pending state stop()");
                    mediaPlayerObject.stop();
                }

                pendingCurrentState = null;
            }

            // Wrapper for removeItems(from, to) so that we can use removeItems(list) until it is implemented upstream
            function removeItemsWrapper(items) {
                var previous = -1, end = -1;

                // Sort indexes backwards so we don't have to deal with offsets when removing
                items.sort(function(a,b) { return b-a; });

                console.debug("To Remove", JSON.stringify(items));

                // Merge ranges of indexes into sets of start, end points
                // and call removeItems as we go along
                for (var i=0; i < items.length; i++) {
                    if (end == -1) {  // first value found set to first
                        end = items[i];
                    } else if (previous - 1 !== items[i]) {  // set has ended (next is not 1 lower)
                        console.debug("RemoveItems", previous, end);
                        player.mediaPlayer.playlist.removeItems(previous, end);

                        end = items[i];  // set new high value for the next set
                    }

                    previous = items[i];  // last value to check if next is 1 lower
                }

                // Remove last set in list as well
                if (items.length > 0) {
                    console.debug("RemoveItems", items[items.length - 1], end);
                    player.mediaPlayer.playlist.removeItems(items[items.length - 1], end);
                }
            }

            function saveQueue(start, end) {
                // FIXME: load and save do not work yet pad.lv/1510225
                // so use our localstorage method for now
                // save("/home/phablet/.local/share/com.ubuntu.music/queue.m3u");
                if (mainView.loadedUI) {
                    // Don't be intelligent, just clear and rebuild the queue for now
                    Library.clearQueue();

                    var sources = [];

                    for (var i=0; i < mediaPlayerPlaylist.itemCount; i++) {
                        sources.push(mediaPlayerPlaylist.itemSource(i));
                    }

                    if (sources.length > 0) {
                        Library.addQueueList(sources);
                    }
                }
            }

            function setCurrentIndex(index) {
                // Set the currentIndex but if the itemCount is too low then wait
                if (index < mediaPlayerPlaylist.itemCount) {
                    mediaPlayerPlaylist.currentIndex = index;
                } else {
                    pendingCurrentIndex = index;
                }
            }

            function setPendingCurrentState(pendingState) {
                // Set the PlaybackState to set once pendingCurrentIndex is set
                pendingCurrentState = pendingState;

                if (pendingCurrentIndex === -1) {
                    processPendingCurrentState();
                }
            }

            function setPendingShuffle(modelSize) {
                // Run next() and play() when the modelSize is reached
                if (modelSize <= itemCount) {
                    mediaPlayerPlaylist.nextWrapper();  // find a random track
                    mediaPlayerObject.play();  // next does not enforce play
                } else {
                    pendingShuffle = modelSize;
                }
            }
        }

        property bool endOfMedia: false
        property double progress: 0

        onDurationChanged: _calcProgress()
        onPositionChanged: _calcProgress()

        onStatusChanged: {
            if (status == MediaPlayer.EndOfMedia && !settings.repeat) {
                console.debug("End of media, stopping.")

                // Tells the onStopped to set the curentIndex = 0
                endOfMedia = true;

                stop();
            }
        }

        onStopped: {  // hit when pressing next() on last track with repeat off
            console.debug("onStopped.")

            // FIXME: Workaround for pad.lv/1494031 in the stopped state
            // we do not get position/duration info so if there are items in
            // the queue and we have stopped instead pause
            if (playlist.itemCount > 0) {
                // We have just ended media so jump to start of playlist
                if (endOfMedia) {
                    playlist.currentIndex = 0;

                    // Play then pause otherwise when we come from EndOfMedia
                    // if calls next() until EndOfMedia again
                    play();
                }

                pause();
            }

            endOfMedia = false;  // always reset endOfMedia
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
