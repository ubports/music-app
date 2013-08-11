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
import Ubuntu.Unity.Action 1.0 as UnityActions
import org.nemomobile.folderlistmodel 1.0
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import QtQuick.XmlListModel 2.0
import "settings.js" as Settings
import "meta-database.js" as Library
import "scrobble.js" as Scrobble
import "playlists.js" as Playlists

MainView {
    objectName: "music"
    applicationName: "music-app"
    id: mainView

    // HUD Actions
    Action {
        id: nextAction
        text: i18n.tr("Next")
        keywords: i18n.tr("Next Track")
        onTriggered: nextSong()
    }
    Action {
        id: playsAction
        text: player.playbackState === MediaPlayer.PlayingState ?
                   i18n.tr("Pause") : i18n.tr("Play")
        keywords: player.playbackState === MediaPlayer.PlayingState ?
                   i18n.tr("Pause Playback") : i18n.tr("Continue or start playback")
        onTriggered: {
            if (player.playbackState === MediaPlayer.PlayingState)  {
                player.pause()
            } else {
                player.play()
            }
        }
    }
    Action {
        id: prevAction
        text: i18n.tr("Previous")
        keywords: i18n.tr("Previous Track")
        onTriggered: previousSong()
    }
    Action {
        id: stopAction
        text: i18n.tr("Stop")
        keywords: i18n.tr("Stop Playback")
        onTriggered: player.stop()
    }
    Action {
        id: settingsAction
        text: i18n.tr("Settings")
        keywords: i18n.tr("Music Settings")
        onTriggered: {
            customdebug('Show settings')
            PopupUtils.open(Qt.resolvedUrl("MusicSettings.qml"), mainView,
                            {
                                title: i18n.tr("Settings")
                            } )
        }
    }
    Action {
        id: quitAction
        text: i18n.tr("Quit")
        keywords: i18n.tr("Close application")
        onTriggered: Qt.quit()
    }

    actions: [nextAction, playsAction, prevAction, stopAction, settingsAction, quitAction]

    Style { id: styleMusic }

    headerColor: styleMusic.mainView.headerColor
    backgroundColor: styleMusic.mainView.backgroundColor
    footerColor: styleMusic.mainView.footerColor

    width: units.gu(50)
    height: units.gu(75)
    Component.onCompleted: {
        customdebug("Version "+appVersion) // print the curren version
        Settings.initialize()
        Library.initialize()
        console.debug("INITIALIZED in tracks")
        if (Settings.getSetting("initialized") !== "true") {
            // initialize settings
            console.debug("reset settings")
            Settings.setSetting("initialized", "true") // setting to make sure the DB is there
            //Settings.setSetting("scrobble", "0") // default state of shuffle
            //Settings.setSetting("scrobble", "0") // default state of scrobble
            Settings.setSetting("currentfolder", folderModel.homePath() + "/Music")
            Playlists.addPlaylist("Testing") // for now, but remove when toolbar works again.
        }
        Library.reset()
        Library.initialize()
        Settings.setSetting("currentfolder", folderModel.path)
        folderScannerModel.path = folderModel.path
        folderScannerModel.nameFilters = ["*.mp3","*.ogg","*.flac","*.wav","*.oga"]
        timer.start()

        // initialize playlists
        Playlists.initializePlaylists()
        Playlists.initializePlaylist()
        // everything else
        random = Settings.getSetting("shuffle") == "1" // shuffle state
        scrobble = Settings.getSetting("scrobble") == "1" // scrobble state
        lastfmusername = Settings.getSetting("lastfmusername") // lastfm username
        lastfmpassword = Settings.getSetting("lastfmpassword") // lastfm password
    }


    // VARIABLES
    property string musicName: i18n.tr("Music")
    property string musicDir: ""
    property string appVersion: '0.5'
    property bool isPlaying: false
    property bool random: false
    property bool scrobble: false
    property string lastfmusername
    property string lastfmpassword
    property string timestamp // used to scrobble

    property string chosenTrack: ""
    property string chosenTitle: ""
    property string chosenArtist: ""
    property string chosenAlbum: ""

    property string currentArtist: ""
    property string currentAlbum: ""
    property string currentTracktitle: ""
    property string currentFile: ""
    property int currentIndex: -1
    property LibraryListModel currentModel: null  // Current model being used
    property var currentQuery: null
    property var currentParam: null
    property string currentCover: ""
    property string currentCoverSmall: currentCover === "" ?
                                           "images/cover_default_icon.png" :
                                           "image://cover-art/" + currentCover
    property string currentCoverFull: currentCover !== "" ?
                                          "image://cover-art-full/" + currentCover :
                                          "images/cover_default.png"

    signal onPlayingTrackChange(string source)

    // FUNCTIONS

    // Custom debug funtion that's easier to shut off
    function customdebug(text) {
        var debug = "1"; // set to "0" for not debugging
        if (debug === "1") {
	    console.debug("Debug: "+text);
        }
    }

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

            // trackQueue must be above 1 otherwise an infinite loop will occur
            do {
                var num = (Math.floor((trackQueue.model.count) * Math.random(seed)));
                console.log(num)
            } while (num == currentIndex && trackQueue.model.count > 1)
            currentIndex = num
            player.source = Qt.resolvedUrl(trackQueue.model.get(num).file)
            console.log("MediaPlayer statusChanged, currentIndex: " + currentIndex)
        } else {
            if ((currentIndex < trackQueue.model.count - 1 && direction === 1 )
                    || (currentIndex > 0 && direction === -1)) {
                console.log("currentIndex: " + currentIndex)
                console.log("trackQueue.count: " + trackQueue.model.count)
                currentIndex += direction
                player.source = Qt.resolvedUrl(trackQueue.model.get(currentIndex).file)
            } else if(direction === 1) {
                console.log("currentIndex: " + currentIndex)
                console.log("trackQueue.count: " + trackQueue.model.count)
                currentIndex = 0
                player.source = Qt.resolvedUrl(trackQueue.model.get(currentIndex).file)
            } else if(direction === -1) {
                console.log("currentIndex: " + currentIndex)
                console.log("trackQueue.count: " + trackQueue.model.count)
                currentIndex = trackQueue.model.count - 1
                player.source = Qt.resolvedUrl(trackQueue.model.get(currentIndex).file)
            }
            console.log("MediaPlayer statusChanged, currentIndex: " + currentIndex)
        }
        player.stop()  // Add stop so that if same song is selected it restarts
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

    // Add items from a stored query in libraryModel into the queue
    function addQueueFromModel(libraryModel)
    {
        var items;

        if (libraryModel.query === null)
        {
            return
        }

        if (libraryModel.param === null)
        {
            items = libraryModel.query()
        }
        else
        {
            items = libraryModel.query(libraryModel.param)
        }

        for (var key in items)
        {
            trackQueue.model.append(items[key])
        }
    }

    function trackClicked(libraryModel, index, play)
    {
        if (play === undefined)
        {
            play = true
        }

        var file = libraryModel.model.get(index).file

        console.debug(player.source, Qt.resolvedUrl(file))

        if (player.source == Qt.resolvedUrl(file))  // same file different pages what should happen then?
        {
            if (play === false)
            {
                return
            }

            console.log("Is current track: "+player.playbackState)

            if (player.playbackState == MediaPlayer.PlayingState)
            {
                player.pause()
            }
            else
            {
                player.play()
            }

            return
        }

        // Clear the play queue and load the new tracks - if not trackQueue
        if (libraryModel !== trackQueue)
        {
            // Don't reload queue if model, query and parameters are the same
            if (currentModel !== libraryModel ||
                    currentQuery !== libraryModel.query ||
                        currentParam !== libraryModel.param)
            {
                trackQueue.model.clear()
                addQueueFromModel(libraryModel)
            }
        }

        // Current index must be updated before player.source
        currentModel = libraryModel
        currentQuery = libraryModel.query
        currentParam = libraryModel.param
        currentIndex = trackQueue.indexOf(file)

        console.log("Click of fileName: " + file)

        if (play === true)
        {
            player.stop()
        }

        player.source = Qt.resolvedUrl(file)

        if (play === true)
        {
            player.play()
        }

        console.log("Source: " + player.source.toString())
        console.log("Index: " + currentIndex)

        return file
    }

    function updateMeta()
    {
        // Load metadata for the track
        currentArtist = trackQueue.model.get(currentIndex).artist
        currentAlbum = trackQueue.model.get(currentIndex).album
        currentTracktitle = trackQueue.model.get(currentIndex).title

        // hasCover and currentCover require no file://
        var file = currentFile

        if (file.indexOf("file://") == 0)
        {
            file = file.slice(7, file.length)
        }

        currentCover = Library.hasCover(file) ? file : ""
    }

    MediaPlayer {
        id: player
        objectName: "player"
        muted: false

        property bool seeking: false;  // Is the user seeking?

        // String versions of pos/dur that labels listen to
        property string durationStr: "00:00"
        property string positionStr: "00:00"

        onSourceChanged: {
            currentFile = source
            onPlayingTrackChange(source)
            updateMeta()
        }

        onStatusChanged: {
            if (status == MediaPlayer.EndOfMedia) {
                // scrobble it
                if (Settings.getSetting("scrobble") === "1") {
                    Scrobble.scrobble(player.source,currentArtist,timestamp)
                }
                else {
                    console.debug("Debug: no scrobbling")
                }

                nextSong() // next track
            }
        }

        // Update the duration text unless seeking (seeking overrides the text)
        onDurationChanged: {
            if (seeking == false)
            {
                durationStr = __durationToString(player.duration)
            }
        }

        // Update the position text unless seeking (seeking overrides the text)
        onPositionChanged: {
            if (seeking == false)
            {
                fileDurationProgressContainer_nowplaying.drawProgress(player.position / player.duration);
                positionStr = __durationToString(player.position)
            }
        }

        onPlaybackStateChanged: {
          mainView.isPlaying = player.playbackState === MediaPlayer.PlayingState
          console.log("mainView.isPlaying=" + mainView.isPlaying)
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
        id: artistTracksModel
    }

    LibraryListModel {
        id: albumModel
    }
    LibraryListModel {
        id: albumTracksModel
    }

    FolderListModel {
        id: folderModel
        showDirectories: true
        filterDirectories: false
        nameFilters: ["*.mp3","*.ogg","*.flac","*.wav","*.oga"] // file types supported.
        path: homePath() + "/Music"
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
    LibraryListModel {
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

    // create the listmodel to use for playlists
    ListModel {
        id: playlistModel
    }

    // create the listmodel for tracks in playlists
    LibraryListModel {
        id: playlisttracksModel
    }


    Column {
        Repeater {
            id: filelist
            width: parent.width
            height: parent.height - units.gu(8)
            anchors.top: parent.top
            model: folderScannerModel

            Component {
                id: fileScannerDelegate
                Rectangle {
                    Component.onCompleted: {
                        if (!model.isDir) {
                            console.log("Debug: Scanner fileDelegate onComplete")
                            if ("" === trackCover) {
                                Library.setMetadata(filePath, trackTitle, trackArtist, trackAlbum, "", trackYear, trackNumber, trackLength)
                            } else {
                                Library.setMetadata(filePath, trackTitle, trackArtist, trackAlbum, "image://cover-art/" + filePath, trackYear, trackNumber, trackLength)
                            }
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: timer
        interval: 200; repeat: true
        running: false
        triggeredOnStart: false
        property int counted: 0

        onTriggered: {
            console.log("Counted: " + counted)
            console.log("filelist.count: " + filelist.count)
            if (counted === filelist.count) {
                console.log("MOVING ON")
                Library.writeDb()
                libraryModel.populate()
                albumModel.filterAlbums()
                artistModel.filterArtists()
                timer.stop()
            }
            counted = filelist.count
        }
    }

    // Popover for tracks, queue and add to playlist, for example
    Component {
        id: trackPopoverComponent
        Popover {
            id: trackPopover
            Column {
                id: containerLayout
                anchors {
                    left: parent.left
                    top: parent.top
                    right: parent.right
                }
                ListItem.Standard {
                    Label {
                        text: i18n.tr("Add to queue")
                        color: styleMusic.popover.labelColor
                        fontSize: "large"
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    onClicked: {
                        console.debug("Debug: Add track to queue: " + chosenTitle)
                        PopupUtils.close(trackPopover)
                        trackQueue.model.append({"title": chosenTitle, "artist": chosenArtist, "file": chosenTrack, "album": chosenAlbum})
                    }
                }
                ListItem.Standard {
                    Label {
                        text: i18n.tr("Add to playlist")
                        color: styleMusic.popover.labelColor
                        fontSize: "large"
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    onClicked: {
                        console.debug("Debug: Add track to playlist")
                        PopupUtils.close(trackPopover)
                        PopupUtils.open(addtoPlaylistDialog, mainView)
                    }
                }
            }
        }
    }

    // Edit name of playlist dialog
    Component {
         id: addtoPlaylistDialog
         Dialog {
             id: dialogueAddToPlaylist
             title: i18n.tr("Add to Playlist")
             text: i18n.tr("Which playlist do you want to add the track to?")

             // show each playlist and make them chosable
             ListView {
                 id: addtoPlaylistView
                 width: parent.width
                 height: units.gu(35)
                 anchors.bottomMargin: units.gu(4)
                 model: playlistModel
                 delegate: ListItem.Standard {
                        text: name
                        onClicked: {
                            console.debug("Debug: "+chosenTrack+" added to "+name)
                            Playlists.addtoPlaylist(name,chosenTrack,chosenArtist,chosenTitle,chosenAlbum)
                            PopupUtils.close(dialogueAddToPlaylist)
                        }
                 }
             }

             Button {
                 text: i18n.tr("Cancel")
                 onClicked: PopupUtils.close(dialogueAddToPlaylist)
             }
         }
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
            }
        }
    }

    Rectangle {
        id: playerControls
        anchors.bottom: parent.bottom
        //anchors.top: filelist.bottom
        height: units.gu(8)
        width: parent.width
        color: styleMusic.playerControls.backgroundColor
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
                    nextSong()
                }
            }
        }
        UbuntuShape {
            id: playshape
            objectName: "playshape"
            height: units.gu(5)
            width: units.gu(5)
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: forwardshape.left
            anchors.rightMargin: units.gu(1)
            radius: "none"
            image: Image {
                id: playindicator
                source: player.playbackState === MediaPlayer.PlayingState ?
                          "images/pause.png" : "images/play.png"
                anchors.right: parent.right
                anchors.centerIn: parent
                opacity: .7
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (player.playbackState === MediaPlayer.PlayingState)  {
                        player.pause()
                    } else {
                        player.play()
                    }
                }
            }
        }
        Image {
            id: iconbottom
            source: mainView.currentCoverSmall
            width: units.gu(6)
            height: units.gu(6)
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: units.gu(1)
            anchors.leftMargin: units.gu(1)

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    header.opacity = 0
                    nowPlaying.visible = true

                }
            }
        }
        Label {
            id: fileTitleBottom
            width: mainView.width - iconbottom.width
                                  - iconbottom.anchors.leftMargin
                                  - playshape.width
                                  - playshape.anchors.rightMargin
                                  - forwardshape.width
                                  - forwardshape.anchors.rightMargin
                                  - anchors.leftMargin
            wrapMode: Text.Wrap
            color: styleMusic.playerControls.labelColor
            maximumLineCount: 1
            fontSize: "medium"
            anchors.left: iconbottom.right
            anchors.top: parent.top
            anchors.topMargin: units.gu(1)
            anchors.leftMargin: units.gu(1)
            text: mainView.currentTracktitle === "" ? mainView.currentFile : mainView.currentTracktitle
        }
        Label {
            id: fileArtistAlbumBottom
            width: mainView.width - iconbottom.width
                                  - iconbottom.anchors.leftMargin
                                  - playshape.width
                                  - playshape.anchors.rightMargin
                                  - forwardshape.width
                                  - forwardshape.anchors.rightMargin
                                  - anchors.leftMargin
            wrapMode: Text.Wrap
            color: styleMusic.playerControls.labelColor
            maximumLineCount: 1
            fontSize: "small"
            anchors.left: iconbottom.right
            anchors.top: fileTitleBottom.bottom
            anchors.leftMargin: units.gu(1)
            text: mainView.currentArtist == "" ? "" : mainView.currentArtist + " - " + mainView.currentAlbum
        }
        Rectangle {
            id: fileDurationProgressContainer
            anchors.bottom: parent.bottom
            anchors.leftMargin: units.gu(1)
            color: styleMusic.playerControls.backgroundColor
            height: units.gu(0.5);
            width: parent.width

            Rectangle {
                id: fileDurationProgressBackground
                color: styleMusic.playerControls.progressBackgroundColor;
                anchors.bottom: parent.bottom
                height: units.gu(0.5);
                radius: units.gu(0.5);
                visible: player.duration > 0 ? true : false
                width: parent.width
            }

            Rectangle {
                id: fileDurationProgressArea
                anchors.bottom: parent.bottom
                color: styleMusic.playerControls.progressForegroundColor;
                height: units.gu(0.5);
                radius: units.gu(0.5);
                visible: player.duration > 0 ? true : false
                width: (player.position / player.duration) * fileDurationProgressContainer.width;
            }
        }

        Label {
            id: fileDurationBottom
            anchors.top: fileArtistAlbumBottom.bottom
            anchors.leftMargin: units.gu(1)
            anchors.left: iconbottom.right
            color: styleMusic.playerControls.labelColor
            fontSize: "small"
            maximumLineCount: 1
            text: player.duration > 0 ?
                      player.positionStr+" / "+player.durationStr
                    : ""
            width: units.gu(30)
            wrapMode: Text.Wrap
        }
    }

    Rectangle {
        id: nowPlaying
        anchors.fill: parent
        height: units.gu(10)
        color: styleMusic.nowPlaying.backgroundColor
        visible: false
        Item {
            anchors.fill: parent
            anchors.bottomMargin: units.gu(3)

            UbuntuShape {
                id: forwardshape_nowplaying
                height: units.gu(7)
                width: units.gu(7)
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
                        nextSong()
                    }
                }
            }
            UbuntuShape {
                id: playshape_nowplaying
                height: units.gu(7)
                width: units.gu(7)
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                radius: "none"
                image: Image {
                    id: playindicator_nowplaying
                    source: player.playbackState === MediaPlayer.PlayingState ?
                              "images/pause.png" : "images/play.png"
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    opacity: .7
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (player.playbackState === MediaPlayer.PlayingState)  {
                            player.pause()
                        } else {
                            player.play()
                        }
                    }
                }
            }
            UbuntuShape {
                id: backshape_nowplaying
                height: units.gu(7)
                width: units.gu(7)
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
                        previousSong()
                    }
                }
            }

            Image {
                id: iconbottom_nowplaying
                source: mainView.currentCoverFull
                width: units.gu(40)
                height: units.gu(40)
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
                            header.opacity = 1
                        }
                    }
                }
            }
            Label {
                id: fileTitleBottom_nowplaying
                width: units.gu(40)
                wrapMode: Text.Wrap
                color: styleMusic.nowPlaying.labelColor
                maximumLineCount: 1
                fontSize: "large"
                anchors.top: iconbottom_nowplaying.bottom
                anchors.topMargin: units.gu(2)
                anchors.leftMargin: units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter
                text: mainView.currentTracktitle === "" ? mainView.currentFile : mainView.currentTracktitle
            }
            Label {
                id: fileArtistAlbumBottom_nowplaying
                width: units.gu(40)
                wrapMode: Text.Wrap
                color: styleMusic.nowPlaying.labelColor
                maximumLineCount: 2
                fontSize: "medium"
                anchors.top: fileTitleBottom_nowplaying.bottom
                anchors.leftMargin: units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter
                text: mainView.currentArtist === "" ? "" : mainView.currentArtist + "\n" + mainView.currentAlbum
            }

            Rectangle {
                id: fileDurationProgressContainer_nowplaying
                anchors.top: fileArtistAlbumBottom_nowplaying.bottom
                anchors.topMargin: units.gu(2)
                anchors.leftMargin: units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter
                color: styleMusic.nowPlaying.backgroundColor;
                height: units.gu(2);
                width: units.gu(40);

                // Function that sets the progress bar value
                function drawProgress(fraction)
                {
                    fileDurationProgress_nowplaying.x = (fraction * fileDurationProgressContainer_nowplaying.width) - fileDurationProgress_nowplaying.width / 2;
                }

                // Function that sets the slider position from the x position of the mouse
                function setSliderPosition(xPosition) {
                    var fraction = xPosition / fileDurationProgressContainer_nowplaying.width;

                    // Make sure fraction is within limits
                    if (fraction > 1.0)
                    {
                        fraction = 1.0;
                    }
                    else if (fraction < 0.0)
                    {
                        fraction = 0.0;
                    }

                    // Update progress bar and position text
                    fileDurationProgressContainer_nowplaying.drawProgress(fraction);
                    player.positionStr = __durationToString(fraction * player.duration);
                }

                // Black background behind the progress bar
                Rectangle {
                    id: fileDurationProgressBackground_nowplaying
                    anchors.verticalCenter: parent.verticalCenter;
                    color: styleMusic.nowPlaying.progressBackgroundColor;
                    height: units.gu(0.5);
                    radius: units.gu(0.5);
                    width: parent.width;
                }

                // The orange fill of the progress bar
                Rectangle {
                    id: fileDurationProgressArea_nowplaying
                    anchors.verticalCenter: parent.verticalCenter;
                    color: styleMusic.nowPlaying.progressForegroundColor;
                    height: units.gu(0.5);
                    radius: units.gu(0.5);
                    width: fileDurationProgress_nowplaying.x + 5;  // +5 so right radius is hidden
                }

                // The current position of the progress bar
                UbuntuShape {
                    id: fileDurationProgress_nowplaying
                    anchors.verticalCenter: fileDurationProgressBackground_nowplaying.verticalCenter;
                    color: styleMusic.nowPlaying.progressHandleColor
                    height: width;
                    width: units.gu(2);
                }

                MouseArea {
                    anchors.fill: parent;
                    onMouseXChanged: { fileDurationProgressContainer_nowplaying.setSliderPosition(mouseX) }
                    onPressed: { player.seeking = true; }
                    onClicked: { fileDurationProgressContainer_nowplaying.setSliderPosition(mouseX) }
                    onReleased: {
                        player.seek((mouseX / fileDurationProgressContainer_nowplaying.width) * player.duration);
                        player.seeking = false;
                    }
                }
            }
            Label {
                id: fileDurationBottom_nowplaying
                anchors.top: fileDurationProgressContainer_nowplaying.bottom
                anchors.topMargin: units.gu(2)
                anchors.leftMargin: units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter
                color: styleMusic.nowPlaying.labelColor
                fontSize: "medium"
                maximumLineCount: 1
                text: player.duration > 0 ? player.positionStr+" / "+player.durationStr : ""
                width: units.gu(40)
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignRight
            }
        }

    }

    // Converts an duration in ms to a formated string ("minutes:seconds")
    function __durationToString(duration) {
        var minutes = Math.floor((duration/1000) / 60);
        var seconds = Math.floor((duration/1000)) % 60;
        return minutes + ":" + (seconds<10 ? "0"+seconds : seconds);
    }

} // end of main view
