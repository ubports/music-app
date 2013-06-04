/*
 * Copyleft Daniel Holm.
 *
 * Authors:
 *  Daniel Holm <d.holmen@gmail.com>
 *  Victor Thompson <victor.thompson@gmail.com>
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
import Ubuntu.Components.Popups 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import org.nemomobile.folderlistmodel 1.0
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import "settings.js" as Settings
import "meta-database.js" as Library
import "playing-list.js" as PlayingList

MainView {
    objectName: i18n.tr("mainView")
    applicationName: i18n.tr("Ubuntu Music App")

    width: units.gu(50)
    height: units.gu(75)
    Component.onCompleted: {
        header.visible = false
    }


    // VARIABLES
    property string musicName: i18n.tr("Music")
    property string musicDir: ""
    property string appVersion: '0.2'
    property int playing: 0
    property int itemnum: 0
    property bool random: false
    property string artist
    property string album
    property string song
    property string tracktitle

    // FUNCTIONS
    function previousSong() {
        getSong(-1)
    }
    function nextSong() {
        getSong(1)
    }

    function getSong(direction) {
        if (random) {
            var now = new Date();
            var seed = now.getSeconds();
            do {
                var num = (Math.floor((PlayingList.size()) * Math.random(seed)));
                console.log(num)
                console.log(playing)
            } while (num == playing && PlayingList.size() > 0)
            player.source = Qt.resolvedUrl(PlayingList.getList()[num])
            musicTracksPage.filelistCurrentIndex = PlayingList.at(num)
            playing = num
            console.log("MediaPlayer statusChanged, currentIndex: " + musicTracksPage.filelistCurrentIndex)
        } else {
            if ((playing < PlayingList.size() - 1 && direction === 1 )
                    || (playing > 0 && direction === -1)) {
                console.log("playing: " + playing)
                console.log("filelistCount: " + musicTracksPage.filelistCount)
                console.log("PlayingList.size(): " + PlayingList.size())
                playing += direction
                if (playing === 0) {
                    musicTracksPage.filelistCurrentIndex = playing + (itemnum - PlayingList.size())
                } else {
                    musicTracksPage.filelistCurrentIndex += direction
                }
                player.source = Qt.resolvedUrl(PlayingList.getList()[playing])
            } else if(direction === 1) {
                console.log("playing: " + playing)
                console.log("filelistCount: " + musicTracksPage.filelistCount)
                console.log("PlayingList.size(): " + PlayingList.size())
                playing = 0
                musicTracksPage.filelistCurrentIndex = playing + (musicTracksPage.filelistCount - PlayingList.size())
                player.source = Qt.resolvedUrl(PlayingList.getList()[playing])
            } else if(direction === -1) {
                console.log("playing: " + playing)
                console.log("filelistCount: " + musicTracksPage.filelistCount)
                console.log("PlayingList.size(): " + PlayingList.size())
                playing = PlayingList.size() - 1
                musicTracksPage.filelistCurrentIndex = playing + (musicTracksPage.filelistCount - PlayingList.size())
                player.source = Qt.resolvedUrl(PlayingList.getList()[playing])
            }
            console.log("MediaPlayer statusChanged, currentIndex: " + musicTracksPage.filelistCurrentIndex)
        }
        console.log("Playing: "+player.source)
        player.play()
    }

    // add track to database
    function addToDatabase(track) {
        // get the needed info of track
        title = getTrackInfo(track, title) // title
        artist = getTrackInfo(track, artist) // artist
        album = getTrackInfo(track, album) // album
        cover = getTrackInfo(track, cover) // cover
        year = getTrackInfo(track, year) // year of album relase
        //tracknr =
        //length =

        // push to database
        Library.setMetadata(track, title, artist, album, cover, year, tracknr, length) // all the data we need.
    }

    MediaPlayer {
        id: player
        muted: false
        onStatusChanged: {
            if (status == MediaPlayer.EndOfMedia) {
                nextSong()
            }
        }

        onPositionChanged: {
            musicTracksPage.needsUpdate = true
        }
    }

    // set the folder from where the music is
    FolderListModel {
        id: folderModel
        showDirectories: false
        //filterDirectories: false
        nameFilters: ["*.mp3", "*.ogg", "*.flac", "*.wav", "*.oga"] // file types suuported.
        path: Settings.getSetting("initialized") === "true" && Settings.getSetting("currentfolder") !== "" ? Settings.getSetting("currentfolder") : homePath() + "/Music"
    }

    /* this is how a queue looks like
    ListElement {
        title: "Dancing in the Moonlight"
        artist: "Thin Lizzy"
        file: "dancing"
    }*/

    // list of tracks on startup. This is just during development
    ListModel {
        id: trackQueue
    }

    // list of songs, which has been removed.
    ListModel {
        id: removedTrackQueue
    }

    // list of single tracks
    ListModel {
        id: singleTracks
    }

    MusicTracks { id: musicTracksPage }

} // main view
