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
import Ubuntu.Components.ListItems 0.1
import Ubuntu.Components.Popups 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Qt.labs.folderlistmodel 1.0
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0

MainView {
    objectName: i18n.tr("mainView")
    applicationName: "Music player"

    width: units.gu(50)
    height: units.gu(75)

    // VARIABLES
    property string musicName: i18n.tr("Music")
    property string musicDir: '/home/daniel/Musik/'
    property string trackStatus: "stopped"
    property string appVersion: '0.3'

    // FUNCTIONS

    // What is the state of the playback?
    function stateChange() {

        // state was stopped (0)
        if (playMusic.playbackState == "0") {
            console.debug("Debug: Music was stopped. Playing")
            beenStopped() // run stop function
            playMusic.play() // then play

            playTrack.iconSource = Qt.resolvedUrl("images/icon_pause@20.png") // change toolbar icon
            playTrack.text = i18n.tr("Pause") // change toolbar text
            trackInfo.text = playMusic.metaData.albumArtist+" - "+playMusic.metaData.title // show track meta data
        }

        // if state was playing (1)
        else if (playMusic.playbackState == "1") {
            console.debug("Debug: Track was playing. Pause")
            playMusic.pause() // pause the music then

            playTrack.iconSource = Qt.resolvedUrl("images/icon_play@20.png") // change toolbar icon
            playTrack.text = i18n.tr("Resume") // change toolbar text
            trackInfo.text = i18n.tr("(Paused) ")+playMusic.metaData.albumArtist+" - "+playMusic.metaData.title // show track meta data
        }

        // if state is paused (2)
        else if (playMusic.playbackState == "2") {
            console.debug("Debug: Track was paused. Playing")
            playMusic.play() // resume then

            playTrack.iconSource = Qt.resolvedUrl("images/icon_pause@20.png") // change toolbar icon
            playTrack.text = i18n.tr("Pause") // change toolbar text
            trackInfo.text = playMusic.metaData.albumArtist+" - "+playMusic.metaData.title // show track meta data
        }
    }

    // stop function
    function beenStopped() {
        console.debug("Debug: has a track been played before or did I just start?")

        // track was just paused or stopped. Resume previous track
        if (playMusic.source != "") {
            console.debug("Debug: Resume previous song: "+playMusic.source)
            trackInfo.text = playMusic.metaData.albumArtist+" - "+playMusic.metaData.title // show track meta data
        }

        // app just started, play random
        else {
            playMusic.source = "/home/daniel/Musik/Cyndi Lauper - 80s music - Time After Time.mp3"
            console.debug("Debug: I was just started. Play random track: "+playMusic.source)
            trackInfo.text = playMusic.metaData.albumArtist+" - "+playMusic.metaData.title // show track meta data
        }
    }

    // previous and next track function
    function nextTrack() {
        console.debug() // print next songs filename
        playMusic.source = musicDir+trackQueue.get(0).file
        playMusic.play()
        removedTrackQueue.append({"title": trackQueue.get(0).title, "artist": trackQueue.get(0).artist, "file": trackQueue.get(0).file}) // move the track to a list of preious tracks
        trackQueue.remove(index) // remove the track from queue
    }

    function previousTrack() {
        console.debug("Debug: Previous track was "+musicDir+removedTrackQueue.get(removedTrackQueue.count).file)
        // play the previous track
        playMusic.source = musicDir+removedTrackQueue.get(removedTrackQueue.count).file
        playMusic.play()
    }

    // end of track
    function hasTrackEnded() {
        if (playMusic.status.EndOfMedia) {
            console.debug("Debug: media ended.")
        }
    }

    // Get song title
    function getTrackInfo(source, type) {
        console.debug('Debug: Got it. Trying to get meta data from: '+source) // debug
        musicInfo.source = source
        musicInfo.pause()

        // if title
        if (type == "title") {
            return musicInfo.metaData.title
        }

        // if artist
        else if (type == "artist") {
            return musicInfo.metaData.albumArtist
        }

        // if album
        else if (type == "album") {
            return musicInfo.metaData.albumTitle
        }

        // year
        else if (type == "year") {
            return musicInfo.metaData.year
        }

        // cover
        /*else if (type == "cover") {
            return musicInfo.metaData.cover
        }*/
    }

    // add track to database
    function addToDatabase(track) {
        // get the needed info of track
        title = getTrackInfo(track, title) // title
        artist = getTrackInfo(track, artist) // artist
        album = getTrackInfo(track, album) // album
        cover = getTrackInfo(track, cover) // cover
        year = getTrackInfo(track, year) // year of album relase

        // push to database
    }


    // run code to check music dir for new stuff

    // Music stuff
    Audio {
        id: playMusic
        source: ""
        /*onEndOfMedia: {
            console.debug("Deub: Track ended. Play next.") //debug
        }*/
    }

    // get file meta data
    Audio {
        id: musicInfo
        source: ""
        volume: 0.0
        //Keys.onSpacePressed: stateChange()
    }

    // list of tracks on startup. This is just during development
    ListModel {
        id: trackQueue
        ListElement {
            title: "Dancing in the Moonlight"
            artist: "Thin Lizzy"
            file: "something"
        }
        ListElement {
            title: "Rock and Roll"
            artist: "Led Zeppelin"
            file: "something else"
        }
        ListElement {
            title: "Moonlight Serenade"
            artist: "Frank Sinatra"
            file: "something completely else"
        }
    }

    // list of songs, which has been removed.
    ListModel {
        id: removedTrackQueue
        ListElement {
            title: "Dancing in the Moonlight"
            artist: "Thin Lizzy"
            file: "dancing"
        }
    }

    Tabs {
        id: tabs
        anchors.fill: parent

        // First tab begins here - should be the primary tab
        Tab {
            objectName: "Tab1"

            title: i18n.tr("Playing")

            // Tab content begins here
            page: Page {
                id: playingPage

                // toolbar
                tools: ToolbarActions {

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
                            //console.debug(musicDir+removedTrackQueue.get(0).file) // print next songs filename
                            //playMusic.source = musicDir+removedTrackQueue.get(0).file
                            //playMusic.play()
                            previousTrack()
                        }
                    }

                    // Play
                    Action {
                        id: playTrack
                        objectName: "play"

                        iconSource: Qt.resolvedUrl("images/icon_play@20.png")
                        text: i18n.tr("Play")

                        onTriggered: {
                            console.debug("Debug: "+trackStatus+" pressed in toolbar.")
                            console.debug(playMusic.playbackState)
                            stateChange()
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
                            console.debug(musicDir+trackQueue.get(0).file) // print next songs filename
                            playMusic.source = musicDir+trackQueue.get(0).file
                            playMusic.play()

                            // move track, which has been played from queue, to old queue so that prev button works
                            removedTrackQueue.append({"title": trackQueue.get(0).title, "artist": trackQueue.get(0).artist, "file": trackQueue.get(0).file})
                            trackQueue.remove(0)
                        }
                    }

                    // Queue
                    Action {
                        id: trackQueueAction
                        objectName: "queuelist"
                        iconSource: Qt.resolvedUrl("images/icon_settings@20.png")
                        text: i18n.tr("Queue")
                        onTriggered: {
                            PopupUtils.open(Qt.resolvedUrl("QueueDialog.qml"), pageLayout,
                                        {
                                            title: i18n.tr("Queue")
                                        } )
                        }
                    }

                    // Settings
                    Action {
                        id: settingsAction
                        objectName: "settings"

                        iconSource: Qt.resolvedUrl("images/icon_settings@20.png")
                        text: i18n.tr("Settings")

                        onTriggered: {
                            console.debug('Debug: Settings pressed')
                            // show settings dialog
                            PopupUtils.open(Qt.resolvedUrl("MusicSettings.qml"), pageLayout,
                                        {
                                            title: i18n.tr("Settings")
                                        } )
                        }
                    }

                }

                Column {
                        id: pageLayout

                        spacing: units.gu(1)

                        Row {
                            spacing: units.gu(1)
                            // Album cover here
                            UbuntuShape {
                                id: trackCoverArt
                                width: units.gu(50)
                                height: units.gu(50)
                                gradientColor: "blue" // test
                                image: Image {
                                    source: "images/music.png"
                                }
                                /*
                                onClicked: {
                                    playMusic.pause()
                                }
                                onPressAndHold: {
                                    playMusic.stop()
                                } */
                            }
                        }

                        // track progress
                        Row {
                            width: parent.width
                            ProgressBar {
                                id: trackProgress
                                minimumValue: 0
                                maximumValue: 100
                                value: 25
                            }
                        }

                        // Track info
                        Row {
                            spacing: units.gu(1)
                            Label {
                                id: trackInfo
                                text: "Stopped. Press play."
                                //subText: "Artist: + Year:"
                            }
                        }
                    }


            }
        }


        // Second tab begins here - artists here
        Tab {
            objectName: "Artists Tab"

            title: i18n.tr("Artists")
            page: Page {
                anchors.margins: units.gu(2)

            // foreach artist:
            ListItem.Standard {
                height: units.gu(4)
                // when pressed on this row, change to albums of artist
                Row {
                    Label {
                        text: i18n.tr("Artist 1")
                    }
                }
            }

                // toolbar here

            Column {
                anchors.centerIn: parent
                anchors.fill: parent
                ListView {
                    id: artistFolder
                    FolderListModel {
                        id: artistModel
                        folder: musicDir
                        nameFilters: ["//\\"];
                        showDirs: true;
                    }
                    width: parent.width
                    height: parent.height
                    model: artistModel
                    delegate: ListItem.Subtitled {
                        text: fileName
                        subText: "totatl albums: "
                        onClicked: {
                            console.debug('Debug: User pressed '+musicDir+fileName)
                        /*    playMusic.source = musicDir+dirName
                            playMusic.play()
                            trackInfo.text = playMusic.metaData.albumArtist+" - "+playMusic.metaData.title // show track meta data
                            */
                        }
                    }
                }
            }
            }
        }

        // Third tab begins here - albums here
        Tab {
            objectName: "Albums Tab"

            title: i18n.tr("Albums")
            page: Page {
                anchors.margins: units.gu(2)

                Column {
                    anchors.centerIn: parent
                    anchors.fill: parent
                    ListView {
                        id: albumFolder
                        FolderListModel {
                            id: albumModel
                            folder: musicDir
                            nameFilters: ["//\\"];
                            showDirs: true;
                        }
                        width: parent.width
                        height: parent.height
                        model: albumModel
                        delegate: ListItem.Subtitled {
                            text: fileName
                            subText: "Year: "
                            onClicked: {
                                console.debug('Debug: User pressed '+musicDir+fileName)
                            /*    playMusic.source = musicDir+dirName
                                playMusic.play()
                                trackInfo.text = playMusic.metaData.albumArtist+" - "+playMusic.metaData.title // show track meta data
                                */
                            }
                        }
                    }
                }

                // toolbar here

                Column {
                    anchors.centerIn: parent
                }
            }
        }

        // Fourth tab - tracks in ~/Music
        Tab {
            objectName: "Tracks Tab"

            title: i18n.tr("Tracks")
            page: Page {
                anchors.margins: units.gu(2)

                // toolbar here

                Column {
                    anchors.centerIn: parent
                    anchors.fill: parent
                    ListView {
                        id: musicFolder
                        FolderListModel {
                            id: folderModel
                            folder: musicDir
                            showDirs: false
                            nameFilters: ["*.ogg","*.mp3","*.oga","*.wav"]
                        }
                        width: parent.width
                        height: parent.height
                        model: folderModel
                        delegate: ListItem.Subtitled {
                            text: fileName
                            subText: "Artist: "
                            onClicked: {
                                playMusic.source = musicDir+fileName
                                playMusic.play()
                                console.debug('Debug: User pressed '+musicDir+fileName)
                                trackInfo.text = playMusic.metaData.albumArtist+" - "+playMusic.metaData.title // show track meta data
                            }
                            onPressAndHold: {
                                console.debug('Debug: '+fileName+' added to queue.')
                                trackQueue.append({"title": playMusic.metaData.title, "artist": playMusic.metaData.albumArtist, "file": fileName})
                            }
                        }
                    }
                }
            }
        }

    } // tabs
} // main view
