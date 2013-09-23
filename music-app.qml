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
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1
import Ubuntu.Components.Popups 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Unity.Action 1.0 as UnityActions
import org.nemomobile.grilo 0.1
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

    // Arguments during startup
    Arguments {
        id: args
        //defaultArgument.help: "Expects URI of the track to play." // should be used when bug is resolved
        //defaultArgument.valueNames: ["URI"] // should be used when bug is resolved
        // grab a file
        Argument {
            name: "file"
            help: "URI for track to run at start."
            required: false
            valueNames: ["track"]
        }
        // Debug/development mode
        Argument {
            name: "debug"
            help: "Start Music in a debug mode. Will show more output."
            required: false
        }
    }

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
            musicSettings.visible = true
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
        customdebug("Arguments on startup: Debug: "+args.values.debug)

        customdebug("Arguments on startup: Debug: "+args.values.debug+ " and file: ")
        if (args.values.file) {
            argFile = args.values.file
            if (argFile.indexOf("file://") != -1) {
                //customdebug("arg contained file://")
                // strip that!
                argFile = argFile.substring(7)
            }
            else {
                // do nothing
                customdebug("arg did not contain file://")
            }
            customdebug(argFile)
        }

        Settings.initialize()
        console.debug("INITIALIZED in tracks")
        if (Settings.getSetting("initialized") !== "true") {
            // initialize settings
            console.debug("reset settings")
            Settings.setSetting("initialized", "true") // setting to make sure the DB is there
            //Settings.setSetting("scrobble", "0") // default state of shuffle
            //Settings.setSetting("scrobble", "0") // default state of scrobble
        }
        Library.reset()

        // initialize playlists
        Playlists.initializePlaylists()
        Playlists.initializePlaylist()
        // everything else
        random = Settings.getSetting("shuffle") == "1" // shuffle state
        scrobble = Settings.getSetting("scrobble") == "1" // scrobble state
        lastfmusername = Settings.getSetting("lastfmusername") // lastfm username
        lastfmpassword = Settings.getSetting("lastfmpassword") // lastfm password

        // push the page to view
        pageStack.push(tabs)
    }


    // VARIABLES
    property string musicName: i18n.tr("Music")
    property string appVersion: '0.7'
    property bool isPlaying: false
    property bool random: false
    property bool scrobble: false
    property string lastfmusername
    property string lastfmpassword
    property string timestamp // used to scrobble
    property string argFile // used for argumented track

    property string chosenTrack: ""
    property string chosenTitle: ""
    property string chosenArtist: ""
    property string chosenAlbum: ""
    property string chosenCover: ""
    property string chosenGenre: ""
    property int chosenIndex: 0

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
                                            currentCover
    property string currentCoverFull: currentCover !== "" ?
                                          currentCover :
                                          "images/cover_default.png"
    property bool queueChanged: false

    signal onPlayingTrackChange(string source)

    // FUNCTIONS

    // Custom debug funtion that's easier to shut off
    function customdebug(text) {
        var debug = true; // set to "0" for not debugging
        //if (args.values.debug) { // *USE LATER*
        if (debug) {
            console.debug("Debug: "+text);
        }
    }

    function previousSong() {
        getSong(-1)
    }


    function nextSong() {
        getSong(1)
    }

    function stopSong() {
        currentIndex = -1;
        player.source = "";  // changing to "" triggers the player to stop and removes the highlight
    }

    function getSong(direction) {
        if (trackQueue.model.count == 0)
        {
            customdebug("No tracks in queue.");
            return;
        }

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

        if (index > libraryModel.model.count - 1 || index < 0)
        {
            customdebug("Incorrect index given to trackClicked.")
            return;
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
                        currentParam !== libraryModel.param ||
                            queueChanged === true)
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
        queueChanged = false

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

        if (play === true)
        {
            nowPlaying.visible = true // Make the queue and Now Playing page active
            nowPlaying.ensureVisibleIndex = index;
        }

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

        currentCover = trackQueue.model.get(currentIndex).cover !== "" ? trackQueue.model.get(currentIndex).cover : "images/cover_default_icon.png"
    }

    // undo removal function to use when swipe to remove
    function undoRemoval (listmodel,index,title,artist,album,file) {
        // show an undo button instead of removed track
        listmodel.set(index, {"title": i18n.tr("Undo")} )
        // set the removed track in undo listmodel
        undo.set(0, {"artist": artist, "title": title, "album": album, "path": file})
    }

    // random color for non-found cover art
    function get_random_color() {
        var letters = '0123456789ABCDEF'.split('');
        var color = '#';
        for (var i = 0; i < 6; i++ ) {
            color += letters[Math.round(Math.random() * 15)];
        }
        return color;
    }

    // WHERE THE MAGIC HAPPENS
    MediaPlayer {
        id: player
        objectName: "player"
        muted: false

        signal positionChange(int position, int duration)

        property bool seeking: false;  // Is the user seeking?

        // String versions of pos/dur that labels listen to
        property string durationStr: "00:00"
        property string positionStr: "00:00"

        onSourceChanged: {
            currentFile = source

            if (source != "" && source != undefined && source !== false)
            {
                onPlayingTrackChange(source)
                updateMeta()
            }
            else
            {
                onPlayingTrackChange(source)  // removes highlight as will get -1 index
                player.stop()
            }
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

            positionChange(position, duration)
        }

        // Update the position text unless seeking (seeking overrides the text)
        onPositionChanged: {
            if (seeking == false)
            {
                positionStr = __durationToString(player.position)
            }

            positionChange(position, duration)
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

    GriloModel {
        id: griloModel

        source: GriloBrowse {
            id: browser
            source: "grl-mediascanner"
            registry: registry
            metadataKeys: [GriloBrowse.Title]
            typeFilter: [GriloBrowse.Audio]
            Component.onCompleted: {
                console.log(browser.supportedKeys);
                console.log(browser.slowKeys);
                refresh();
                console.log("Refreshing");
            }

            onAvailableChanged: {
                console.log("Available ? " + available);
                if (available === true) {
                    console.log("griloModel.count " + griloModel.count)
                }
            }
            onBaseMediaChanged: refresh();
        }

        onCountChanged: {
            if (count > 0) {
                timer.start()
                for (var i = timer.counted; i < griloModel.count; i++)
                {
                    var file = griloModel.get(i).url.toString()
                    if (file.indexOf("file://") == 0)
                    {
                        file = file.slice(7, file.length)
                    }
                    console.log("Artist:"+ griloModel.get(i).artist + ", Album:"+griloModel.get(i).album + ", Title:"+griloModel.get(i).title + ", File:"+file + ", Cover:"+griloModel.get(i).thumbnail + ", Number:"+griloModel.get(i).trackNumber + ", Genre:"+griloModel.get(i).genre);
                    Library.setMetadata(file, griloModel.get(i).title, griloModel.get(i).artist, griloModel.get(i).album, griloModel.get(i).thumbnail, griloModel.get(i).year, griloModel.get(i).trackNumber, griloModel.get(i).duration, griloModel.get(i).genre)
                }
            }

        }
    }

    GriloRegistry {
        id: registry

        Component.onCompleted: {
            console.log("Registry is ready");
            loadAll();
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

    LibraryListModel {
        id: recentAlbumTracksModel
    }

    LibraryListModel {
        id: genreModel
    }

    LibraryListModel {
        id: genreTracksModel
    }

    // list of tracks on startup. This is just during development
    LibraryListModel {
        id: trackQueue
        property bool isEmpty: count == 0

        onIsEmptyChanged: {
            /*
             * If changed to false then must have been empty before
             * Therefore set the first song as the current item
             * and update any metadata
             */
            if (isEmpty === false && currentIndex == -1 && player.source == "")
            {
                currentIndex = 0;
                player.source = trackQueue.model.get(currentIndex).file;
                updateMeta();
            }
        }
    }

    // list of songs, which has been removed.
    ListModel {
        id: removedTrackQueue
    }

    // list of single tracks
    ListModel {
        id: singleTracksgriloMo
    }

    // create the listmodel to use for playlists
    ListModel {
        id: playlistModel
    }

    // create the listmodel for tracks in playlists
    LibraryListModel {
        id: playlisttracksModel
    }

    // ListModel for Undo functionality
    ListModel {
        id: undo
    }

    Timer {
        id: timer
        interval: 200; repeat: true
        running: false
        triggeredOnStart: false
        property int counted: 0

        onTriggered: {
            console.log("Counted: " + counted)
            console.log("griloModel.count: " + griloModel.count)
            if (counted === griloModel.count) {
                console.log("MOVING ON")
                Library.writeDb()
                libraryModel.populate()
                albumModel.filterAlbums()
                artistModel.filterArtists()
                genreModel.filterGenres()
                timer.stop()

                // Check if tracks have been found, if none then show message
                if (counted === 0)
                {
                    header.opacity = 0;
                    libraryEmpty.visible = true;
                }
            }
            counted = griloModel.count
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
                        trackQueue.model.append({"title": chosenTitle, "artist": chosenArtist, "file": chosenTrack, "album": chosenAlbum, "cover": chosenCover, "genre": chosenGenre})
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
                        PopupUtils.open(Qt.resolvedUrl("MusicaddtoPlaylist.qml"), mainView,
                                        {
                                            title: i18n.tr("Select playlist")
                                        } )
                    }
                }
            }
        }
    }

    // New playlist dialog
    Component {
         id: newPlaylistDialog
         Dialog {
             id: dialogueNewPlaylist
             title: i18n.tr("New Playlist")
             text: i18n.tr("Name your playlist.")
             TextField {
                 id: playlistName
                 placeholderText: i18n.tr("Name")
             }
             ListItem.Standard {
                 id: newplaylistoutput
                 visible: false // should only be visible when an error is made.
             }

             Button {
                 text: i18n.tr("Create")
                 onClicked: {
                     newplaylistoutput.visible = false // make sure its hidden now if there was an error last time
                     if (playlistName.text.length > 0) { // make sure something is acually inputed
                         var newList = Playlists.addPlaylist(playlistName.text)
                         if (newList === "OK") {
                             console.debug("Debug: User created a new playlist named: "+playlistName.text)
                             // add the new playlist to the tab
                             var index = Playlists.getID(); // get the latest ID
                             playlistModel.append({"id": index, "name": playlistName.text, "count": "0"})
                         }
                         else {
                             console.debug("Debug: Something went wrong: "+newList)
                             newplaylistoutput.visible = true
                             newplaylistoutput.text = i18n.tr("Error: "+newList)
                         }

                         PopupUtils.close(dialogueNewPlaylist)
                     }
                     else {
                         newplaylistoutput.visible = true
                         newplaylistoutput.text = i18n.tr("Error: You didn't type a name.")
                     }
                }
             }

             Button {
                 text: i18n.tr("Cancel")
                 color: styleMusic.dialog.buttonColor
                 onClicked: PopupUtils.close(dialogueNewPlaylist)
             }
         }
    }

    PageStack {
        id: pageStack
        anchors.top: mainView.top
        Tabs {
            id: tabs
            anchors.fill: parent

            // First tab is all music
            Tab {
                id: startTab
                objectName: "starttab"
                anchors.fill: parent
                title: i18n.tr("Music")

                // Tab content begins here
                page: MusicStart {
                    id: musicStartPage
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

            // fourth tab is all songs
            Tab {
                id: tracksTab
                objectName: "trackstab"
                anchors.fill: parent
                title: i18n.tr("Songs")

                // Tab content begins here
                page: MusicTracks {
                    id: musicTracksPage
                }
            }


            // fifth tab is the playlists
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
        } // end of tabs
    }

    // player controls at the bottom
    Rectangle {
        id: playerControls
        anchors.bottom: parent.bottom
        //anchors.top: filelist.bottom
        height: units.gu(8)
        width: parent.width
        color: styleMusic.playerControls.backgroundColor

        state: trackQueue.isEmpty === true ? "disabled" : "enabled"

        states: [
            State {
                name: "disabled"
                PropertyChanges {
                    target: disabledPlayerControlsGroup
                    visible: true
                }
                PropertyChanges {
                    target: enabledPlayerControlsGroup
                    visible: false
                }
            },
            State {
                name: "enabled"
                PropertyChanges {
                    target: disabledPlayerControlsGroup
                    visible: false
                }
                PropertyChanges {
                    target: enabledPlayerControlsGroup
                    visible: true
                }
            }
        ]

        Rectangle {
            id: disabledPlayerControlsGroup
            anchors.fill: parent
            color: "transparent"
            visible: trackQueue.isEmpty === true

            Label {
                id: noSongsInQueueLabel
                anchors.left: parent.left
                anchors.margins: units.gu(1)
                anchors.top: parent.top
                color: styleMusic.playerControls.labelColor
                text: "No songs queued"
                fontSize: "large"
            }

            Label {
                id: tabToStartPlayingLabel
                color: styleMusic.playerControls.labelColor
                anchors.left: parent.left
                anchors.margins: units.gu(1)
                anchors.top: noSongsInQueueLabel.bottom
                text: "Tap on a song to start playing"
            }
        }

        Rectangle {
            id: enabledPlayerControlsGroup
            anchors.fill: parent
            color: "transparent"
            visible: trackQueue.isEmpty === false

            UbuntuShape {
                id: forwardshape
                objectName: "forwardshape"
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
    }

    MusicNowPlaying {
        id: nowPlaying
    }

    MusicaddtoPlaylist {
        id: addtoPlaylist
    }

    // Converts an duration in ms to a formated string ("minutes:seconds")
    function __durationToString(duration) {
        var minutes = Math.floor((duration/1000) / 60);
        var seconds = Math.floor((duration/1000)) % 60;
        return minutes + ":" + (seconds<10 ? "0"+seconds : seconds);
    }

    // Overlay to show when no tracks detected on the device
    Rectangle {
        id: libraryEmpty
        anchors.fill: parent
        color: styleMusic.libraryEmpty.backgroundColor
        visible: false

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            color: styleMusic.libraryEmpty.labelColor
            fontSize: "medium"
            text: "Please import music and restart the app"
        }

    }

} // end of main view
