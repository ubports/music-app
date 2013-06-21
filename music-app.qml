/*
 * Copyright (C) 2013 Victor Thompson <victor.thompson@gmail.com>
 *                    Daniel Holm <d.holmen@gmail.com>
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
import QtQuick.XmlListModel 2.0
import "settings.js" as Settings
import "meta-database.js" as Library
import "playing-list.js" as PlayingList
import "scrobble.js" as Scrobble
import "playlists.js" as Playlists

MainView {
    objectName: i18n.tr("mainView")
    applicationName: i18n.tr("music-app")
    id: mainView

    width: units.gu(50)
    height: units.gu(75)
    Component.onCompleted: {
        libraryModel.populate()
        albumModel.filterAlbums()
        artistModel.populate()
    }


    // VARIABLES
    property string musicName: i18n.tr("Music")
    property string musicDir: ""
    property string appVersion: '0.3'
    property int playing: 0
    property int itemnum: 0
    property bool random: false
    property bool scrobble: false
    property string artist
    property string album
    property string song
    property string tracktitle
    property string lastfmusername
    property string lastfmpassword
    property string timestamp // used to scrobble

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
        timestamp = new Date().getTime(); // contains current date and time in Unix time, used to scrobble
        // scrobble it
        if (Settings.getSetting("scrobble") === "1") {
            Scrobble.now_playing(player.source,timestamp) // send "now playing" to last.fm
        }
        else {
            console.debug("Debug: no scrobbling")
        }
    }

    MediaPlayer {
        id: player
        muted: false
        onStatusChanged: {
            if (status == MediaPlayer.EndOfMedia) {
                // scrobble it
                if (Settings.getSetting("scrobble") === "1") {
                    Scrobble.scrobble(player.source,artist,timestamp)
                }
                else {
                    console.debug("Debug: no scrobbling")
                }

                nextSong() // next track
            }
        }

        onPositionChanged: {
            musicTracksPage.needsUpdate = true
        }
    }

    // Model to send the data
    XmlListModel {
        id: scrobblemodel
        query: "/"

        function rpcRequest(request,handler) {
            var http = new XMLHttpRequest()

            http.open("POST",scrobble_url,true)
            http.setRequestHeader("User-Agent", "Music-App/"+appVersion)
            http.setRequestHeader("Content-type", "text/xml")
            http.setRequestHeader("Content-length", request.length)
            if (root.authenticate) {
                http.setRequestHeader("Authorization", "Basic " + Qt.btoa(lastfmusername+":"+lastfmusername))
            }
            http.setRequestHeader("Connection", "close")
            http.onreadystatechange = function() {
                if(http.readyState == 4 && http.status == 200) {
                    console.debug("Debug: XmlRpc::rpcRequest.onreadystatechange()")
                    handler(http.responseText)
                }
            }
            http.send(request)
        }

        function callHandler(response) {
            xml = response
        }

        function call(cmd,params) {
            console.debug("Debug: XmlRpc.call(",cmd,params,")")
            var request = ""
            request += "<?xml version='1.0'?>"
            request += "<methodCall>"
            request += "<methodName>" + cmd + "</methodName>"
            request += "<params>"
            for (var i=0; i<params.length; i++) {
            request += "<param><value>"
            if (typeof(params[i])=="string") {
                request += "<string>" + params[i] + "</string>"
            }
            if (typeof(params[i])=="number") {
                request += "<int>" + params[i] + "</int>"
            }
            request += "</value></param>"
            }
            request += "</params>"
            request += "</methodCall>"
            rpcRequest(request,callHandler)
        }
    }

    LibraryListModel {
        id: libraryModel
    }

    LibraryListModel {
        id: artistModel
    }

    LibraryListModel {
        id: albumModel
    }

    LibraryListModel {
        id: playlistModel
    }

    FolderListModel {
        id: folderModel
        showDirectories: true
        filterDirectories: false
        nameFilters: ["*.mp3","*.ogg","*.flac","*.wav","*.oga"] // file types supported.
        path: Settings.getSetting("initialized") === "true" && Settings.getSetting("currentfolder") !== "" ? Settings.getSetting("currentfolder") : homePath() + "/Music"
        onPathChanged: {
            console.log("Path changed: " + folderModel.path)
        }
    }

    FolderListModel {
        id: folderScannerModel
        property int count: 0
        readsMediaMetadata: true
        isRecursive: true
        showDirectories: true
        filterDirectories: false
        nameFilters: ["*.mp3","*.ogg","*.flac","*.wav","*.oga"] // file types supported.
        onPathChanged: {
            console.log("Scanner Path changed: " + folderModel.path)
        }
    }

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

    Tabs {
        id: tabs
        anchors.fill: parent

        // First tab is all music
        Tab {
            id: musicTab
            objectName: "musictab"
            anchors.fill: parent
            title: i18n.tr("Music")

            // Tab content begins here
            page: MusicTracks {
                id: musicTracksPage
            }
        }

        // Second tab is arists
        Tab {
            id: artistsTab
            objectName: "artiststab"
            anchors.fill: parent
            title: i18n.tr("Artists")

            // tab content
            page: MusicArtists {
                id: musicArtistsPage

                tools: ToolbarActions {
                    // Queue dialog
                    Action {
                        objectName: "queuesaction"

                        iconSource: Qt.resolvedUrl("images/folder.png") // change this icon later
                        text: i18n.tr("Queue")

                        onTriggered: {
                            console.debug('Debug: Show queue')
                            PopupUtils.open(Qt.resolvedUrl("QueueDialog.qml"), mainView,
                                            {
                                                title: i18n.tr("Queue")
                                            } )
                        }
                    }
                }
            }
        }

        // third tab is albums
        Tab {
            id: albumsTab
            objectName: "albumstab"
            anchors.fill: parent
            title: i18n.tr("Albums")

            // Tab content begins here
            page: MusicAlbums {
                id: musicAlbumsPage

                tools: ToolbarActions {
                    // Queue dialog
                    Action {
                        objectName: "queuesaction"

                        iconSource: Qt.resolvedUrl("images/folder.png") // change this icon later
                        text: i18n.tr("Queue")

                        onTriggered: {
                            console.debug('Debug: Show queue')
                            PopupUtils.open(Qt.resolvedUrl("QueueDialog.qml"), mainView,
                                            {
                                                title: i18n.tr("Queue")
                                            } )
                        }
                    }
                }
            }
        }

        // fourth tab is the playlists
        Tab {
            id: playlistTab
            objectName: "playlisttab"
            anchors.fill: parent
            title: i18n.tr("Playlists")

            // Tab content begins here
            page: MusicPlaylists {
                id: musicPlaylistPage

                tools: ToolbarActions {
                    // import playlist from lastfm
                    Action {
                        objectName: "lastfmplaylistaction"

                        iconSource: Qt.resolvedUrl("images/lastfm.png")
                        text: i18n.tr("Get from Last.fm")

                        onTriggered: {
                            console.debug("Debug: User pressed action to import playlist from lastfm")
                            Scrobble.getPlaylists(Settings.getSetting("lastfmusername"))
                        }
                    }

                    // Queue dialog
                    Action {
                        objectName: "queuesaction"

                        iconSource: Qt.resolvedUrl("images/folder.png") // change this icon later
                        text: i18n.tr("Queue")

                        onTriggered: {
                            console.debug('Debug: Show queue')
                            PopupUtils.open(Qt.resolvedUrl("QueueDialog.qml"), mainView,
                                            {
                                                title: i18n.tr("Queue")
                                            } )
                        }
                    }
                }
            }
        }

        // Fifth is the settings
        /* FIX LATER
        Tab {
            id: settingsTab
            objectName: "settingstab"
            anchors.fill: parent
            title: i18n.tr("Settings")

            // Tab content begins here
            page: MusicSettings {
                id: musicSettings
            }
        } */
    }

    Rectangle {
        id: playerControls
        anchors.bottom: parent.bottom
        //anchors.top: filelist.bottom
        height: units.gu(8)
        width: parent.width
        color: "#333333"
        UbuntuShape {
            id: forwardshape
            height: units.gu(5)
            width: units.gu(5)
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: units.gu(2)
            radius: "none"
            image: Image {
                id: forwardindicator
                source: "images/forward.png"
                anchors.right: parent.right
                anchors.centerIn: parent
                opacity: .7
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    playindicator.source = "images/pause.png"
                    playindicator_nowplaying.source = playindicator.source
                    nextSong()
                }
            }
        }
        UbuntuShape {
            id: playshape
            height: units.gu(5)
            width: units.gu(5)
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: forwardshape.left
            anchors.rightMargin: units.gu(1)
            radius: "none"
            image: Image {
                id: playindicator
                source: "images/play.png"
                anchors.right: parent.right
                anchors.centerIn: parent
                opacity: .7
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (player.playbackState === MediaPlayer.PlayingState)  {
                        playindicator.source = "images/play.png"
                        player.pause()
                    } else {
                        playindicator.source = "images/pause.png"
                        player.play()
                    }
                    playindicator_nowplaying.source = playindicator.source
                }
            }
        }
        Image {
            id: iconbottom
            source: ""
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: units.gu(1)
            anchors.leftMargin: units.gu(1)

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    nowPlaying.visible = true
                    header.visible = false
                }
            }
        }
        Label {
            id: fileTitleBottom
            width: units.gu(30)
            wrapMode: Text.Wrap
            color: "#FFFFFF"
            maximumLineCount: 1
            font.pixelSize: 16
            anchors.left: iconbottom.right
            anchors.top: parent.top
            anchors.topMargin: units.gu(1)
            anchors.leftMargin: units.gu(1)
            text: ""
        }
        Label {
            id: fileArtistAlbumBottom
            width: units.gu(30)
            wrapMode: Text.Wrap
            color: "#FFFFFF"
            maximumLineCount: 1
            font.pixelSize: 12
            anchors.left: iconbottom.right
            anchors.top: fileTitleBottom.bottom
            anchors.leftMargin: units.gu(1)
            text: ""
        }
        Rectangle {
            id: fileDurationProgressContainer
            anchors.top: fileArtistAlbumBottom.bottom
            anchors.left: iconbottom.right
            anchors.topMargin: 2
            anchors.leftMargin: units.gu(1)
            width: units.gu(20)
            color: "#333333"

            Rectangle {
                id: fileDurationProgressBackground
                anchors.top: parent.top
                anchors.topMargin: 2
                height: 1
                width: units.gu(20)
                color: "#FFFFFF"
                visible: false
            }
            Rectangle {
                id: fileDurationProgress
                anchors.top: parent.top
                height: 5
                width: 0
                color: "#DD4814"
            }
        }
        Label {
            id: fileDurationBottom
            anchors.top: fileArtistAlbumBottom.bottom
            anchors.left: fileDurationProgressContainer.right
            anchors.leftMargin: units.gu(1)
            width: units.gu(30)
            wrapMode: Text.Wrap
            color: "#FFFFFF"
            maximumLineCount: 1
            font.pixelSize: 12
            text: ""
        }
    }

    Rectangle {
        id: nowPlaying
        anchors.fill: parent
        height: units.gu(10)
        color: "#333333"
        visible: false
        Column {
            anchors.fill: parent
            anchors.bottomMargin: units.gu(10)

            UbuntuShape {
                id: forwardshape_nowplaying
                height: 50
                width: 50
                anchors.bottom: parent.bottom
                anchors.left: playshape_nowplaying.right
                anchors.leftMargin: units.gu(2)
                radius: "none"
                image: Image {
                    id: forwardindicator_nowplaying
                    source: "images/forward.png"
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    opacity: .7
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        playindicator.source = "images/pause.png"
                        playindicator_nowplaying.source = playindicator.source
                        nextSong()
                    }
                }
            }
            UbuntuShape {
                id: playshape_nowplaying
                height: 50
                width: 50
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                radius: "none"
                image: Image {
                    id: playindicator_nowplaying
                    source: "images/play.png"
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    opacity: .7
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (player.playbackState === MediaPlayer.PlayingState)  {
                            playindicator.source = "images/play.png"
                            player.pause()
                        } else {
                            playindicator.source = "images/pause.png"
                            player.play()
                        }
                        playindicator_nowplaying.source = playindicator.source
                    }
                }
            }
            UbuntuShape {
                id: backshape_nowplaying
                height: 50
                width: 50
                anchors.bottom: parent.bottom
                anchors.right: playshape_nowplaying.left
                anchors.rightMargin: units.gu(2)
                radius: "none"
                image: Image {
                    id: backindicator_nowplaying
                    source: "images/back.png"
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    opacity: .7
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        playindicator.source = "images/pause.png"
                        playindicator_nowplaying.source = playindicator.source
                        previousSong()
                    }
                }
            }

            Image {
                id: iconbottom_nowplaying
                source: ""
                width: 300
                height: 300
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: units.gu(1)
                anchors.leftMargin: units.gu(1)

                MouseArea {
                    anchors.fill: parent
                    signal swipeRight;
                    signal swipeLeft;
                    signal swipeUp;
                    signal swipeDown;

                    property int startX;
                    property int startY;

                    onPressed: {
                        startX = mouse.x;
                        startY = mouse.y;
                    }

                    onReleased: {
                        var deltax = mouse.x - startX;
                        var deltay = mouse.y - startY;

                        if (Math.abs(deltax) > 50 || Math.abs(deltay) > 50) {
                            if (deltax > 30 && Math.abs(deltay) < 30) {
                                // swipe right
                                previousSong();
                            } else if (deltax < -30 && Math.abs(deltay) < 30) {
                                // swipe left
                                nextSong();
                            }
                        } else {
                            nowPlaying.visible = false
                            header.visible = true
                        }
                    }
                }
            }
            Label {
                id: fileTitleBottom_nowplaying
                width: units.gu(45)
                wrapMode: Text.Wrap
                color: "#FFFFFF"
                maximumLineCount: 1
                font.pixelSize: 24
                anchors.top: iconbottom_nowplaying.bottom
                anchors.topMargin: units.gu(2)
                anchors.left: parent.left
                anchors.leftMargin: units.gu(2)
                text: ""
            }
            Label {
                id: fileArtistAlbumBottom_nowplaying
                width: units.gu(45)
                wrapMode: Text.Wrap
                color: "#FFFFFF"
                maximumLineCount: 2
                font.pixelSize: 16
                anchors.left: parent.left
                anchors.top: fileTitleBottom_nowplaying.bottom
                anchors.leftMargin: units.gu(2)
                text: ""
            }
            Rectangle {
                id: fileDurationProgressContainer_nowplaying
                anchors.top: fileArtistAlbumBottom_nowplaying.bottom
                anchors.left: parent.left
                anchors.topMargin: units.gu(2)
                anchors.leftMargin: units.gu(2)
                width: units.gu(40)
                color: "#333333"

                Rectangle {
                    id: fileDurationProgressBackground_nowplaying
                    anchors.top: parent.top
                    anchors.topMargin: 4
                    height: 1
                    width: units.gu(40)
                    color: "#FFFFFF"
                    visible: false
                }
                Rectangle {
                    id: fileDurationProgress_nowplaying
                    anchors.top: parent.top
                    height: 8
                    width: 0
                    color: "#DD4814"
                }
            }
            Label {
                id: fileDurationBottom_nowplaying
                anchors.top: fileDurationProgressContainer_nowplaying.bottom
                anchors.left: parent.left
                anchors.topMargin: units.gu(2)
                anchors.leftMargin: units.gu(2)
                width: units.gu(30)
                wrapMode: Text.Wrap
                color: "#FFFFFF"
                maximumLineCount: 1
                font.pixelSize: 16
                text: ""
            }
        }

    }

} // end of main view
