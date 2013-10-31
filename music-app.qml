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
import QtPowerd 0.1
import org.nemomobile.grilo 0.1
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import QtQuick.XmlListModel 2.0
import QtGraphicalEffects 1.0
import UserMetrics 0.1
import "settings.js" as Settings
import "meta-database.js" as Library
import "scrobble.js" as Scrobble
import "playlists.js" as Playlists
import "common"

MainView {
    objectName: "music"
    applicationName: "com.ubuntu.music"
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
        id: backAction
        text: i18n.tr("Back")
        keywords: i18n.tr("Go back to last page")
        onTriggered: musicToolbar.goBack();
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

    actions: [nextAction, playsAction, prevAction, stopAction, backAction, settingsAction, quitAction]

    // signal to open new URIs
    // TODO currently this only allows playing file:// URIs of known files
    // (already in the database), not e.g. http:// URIs or files in directories
    // not picked up by Grilo
    Connections {
        target: UriHandler
        onOpened: {
            // clear play queue
            trackQueue.model.clear()
            for (var i=0; i < uris.length; i++) {
                console.debug("URI=" + uris[i])
                // skip non-file:// URIs
                if (uris[i].substring(0, 7) !== "file://") {
                    console.debug("Unsupported URI " + uris[i] + ", skipping")
                    continue
                }

                // search pathname in library
                var file = decodeURIComponent(uris[i])
                var index = libraryModel.indexOf(file)
                if (index <= -1) {
                    console.debug("Unknown file " + file + ", skipping")
                    continue
                }

                // enqueue
                trackQueue.model.append(libraryModel.model.get(index))

                // play first URI
                if (i == 0) {
                    trackClicked(trackQueue, 0, true)
                }
            }
        }
    }

    // UserMetrics to show Music stuff on welcome screen
    Metric {
        id: songsMetric
        name: "music-metrics"
        format: "<b>%1</b> songs played today"
        emptyFormat: "No songs played today"
        domain: "com.ubuntu.music"
    }

    // Design stuff
    Style { id: styleMusic }
    width: units.gu(50)
    height: units.gu(75)

    // Run on startup
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
            Settings.setSetting("snaptrack", "1") // default state of snaptrack
            Settings.setSetting("shuffle", "0") // default state of shuffle
            Settings.setSetting("repeat", "0") // default state of repeat
            //Settings.setSetting("scrobble", "0") // default state of scrobble
        }
        Library.reset()

        // initialize playlists
        Playlists.initializePlaylists()
        Playlists.initializePlaylist()
        // everything else
        loading.visible = true
        random = Settings.getSetting("shuffle") == "1" // shuffle state
        scrobble = Settings.getSetting("scrobble") == "1" // scrobble state
        lastfmusername = Settings.getSetting("lastfmusername") // lastfm username
        lastfmpassword = Settings.getSetting("lastfmpassword") // lastfm password

        // push the page to view
        pageStack.push(tabs)
    }


    // VARIABLES
    property string musicName: i18n.tr("Music")
    property string appVersion: '1.1'
    property bool isPlaying: false
    property bool hasRecent: !Library.isRecentEmpty()
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
    signal collapseExpand(int index);
    signal onPlayingTrackChange(string source)
    signal onToolbarShownChanged(bool shown, var currentPage, var currentTab)

    // FUNCTIONS

    // Custom debug funtion that's easier to shut off
    function customdebug(text) {
        var debug = true; // set to "0" for not debugging
        //if (args.values.debug) { // *USE LATER*
        if (debug) {
            console.debug(i18n.tr("Debug: ")+text);
        }
    }

    function previousSong(startPlaying) {
        getSong(-1, startPlaying)
    }


    function nextSong(startPlaying, fromControls) {
        getSong(1, startPlaying, fromControls)
    }

    function stopSong() {
        currentIndex = -1;
        player.source = "";  // changing to "" triggers the player to stop and removes the highlight
    }

    function getSong(direction, startPlaying, fromControls) {
        if (trackQueue.model.count == 0)
        {
            customdebug("No tracks in queue.");
            return;
        }

        if (startPlaying === undefined)  // default startPlaying to true
        {
            startPlaying = true;
        }

        if (fromControls === undefined)  // default fromControls to true
        {
            fromControls = true;
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

                // Seek to start if threshold reached when selecting previous
                if (direction === -1 && (player.position / 1000) > 5)
                {
                    player.seek(0);  // seek to start
                    return;
                }

                currentIndex += direction
                player.source = Qt.resolvedUrl(trackQueue.model.get(currentIndex).file)
            } else if(direction === 1 && (Settings.getSetting("repeat") === "1" || fromControls)) {
                console.log("currentIndex: " + currentIndex)
                console.log("trackQueue.count: " + trackQueue.model.count)
                currentIndex = 0
                player.source = Qt.resolvedUrl(trackQueue.model.get(currentIndex).file)
            } else if(direction === -1 && (Settings.getSetting("repeat") === "1" || fromControls)) {
                console.log("currentIndex: " + currentIndex)
                console.log("trackQueue.count: " + trackQueue.model.count)
                currentIndex = trackQueue.model.count - 1
                player.source = Qt.resolvedUrl(trackQueue.model.get(currentIndex).file)
            }
            else
            {
                player.stop()
                return;
            }

            console.log("MediaPlayer statusChanged, currentIndex: " + currentIndex)
        }
        player.stop()  // Add stop so that if same song is selected it restarts
        console.log("Playing: "+player.source)

        if (startPlaying === true)  // only start the track if told
        {
            player.play()
        }

        timestamp = new Date().getTime(); // contains current date and time in Unix time, used to scrobble
        // scrobble it
        if (Settings.getSetting("scrobble") === "1") {
            Scrobble.now_playing(player.source,timestamp) // send "now playing" to last.fm
        }
        else {
            console.debug("Debug: no scrobbling")
        }
        songsMetric.increment() // Increment song count on Welcome screen
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

        // Clear the play queue and load the new tracks - if not trackQueue
        // Don't reload queue if model, query and parameters are the same
        // Same file different pages is treated as a new session
        if (libraryModel !== trackQueue &&
                (currentModel !== libraryModel ||
                    currentQuery !== libraryModel.query ||
                        currentParam !== libraryModel.param ||
                            queueChanged === true))
        {
                trackQueue.model.clear()
                addQueueFromModel(libraryModel)
        }
        else if (player.source == Qt.resolvedUrl(file))
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

                // Show the Now Playing page and make sure the track is visible
                nowPlaying.visible = true;
                nowPlaying.ensureVisibleIndex = index;

                musicToolbar.showToolbar();
            }

            return
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
            songsMetric.increment() // Increment song count on Welcome screen
        }

        console.log("Source: " + player.source.toString())
        console.log("Index: " + currentIndex)

        if (play === true)
        {
            // Show the Now Playing page and make sure the track is visible
            nowPlaying.visible = true;
            nowPlaying.ensureVisibleIndex = index;

            musicToolbar.showToolbar();
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
    function undoRemoval(listmodel,row) {
        // show an undo button instead of removed track
        //listmodel.insert(row.index, {"title": i18n.tr("Undo")} )
        // set the removed track in undo listmodel
        undo.set(0, row)
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

                nextSong (true, false) // next track
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
          QtPowerd.keepAlive = mainView.isPlaying
          console.log("mainView.isPlaying=" + mainView.isPlaying + ", QtPowerd.keepAlive=" + QtPowerd.keepAlive)
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
        property bool loaded: false

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

            onFinished: {
                for (var i = 0; i < griloModel.count; i++)
                {
                    var media = griloModel.get(i)
                    var file = media.url.toString()
                    if (file.indexOf("file://") == 0)
                    {
                        file = file.slice(7, file.length)
                    }
                    //console.log("Artist:"+ media.artist + ", Album:"+media.album + ", Title:"+media.title + ", File:"+file + ", Cover:"+media.thumbnail + ", Number:"+media.trackNumber + ", Genre:"+media.genre);
                    Library.setMetadata(file, media.title, media.artist, media.album, media.thumbnail, media.year, media.trackNumber, media.duration, media.genre)
                }
                Library.writeDb()
                recentModel.filterRecent()
                genreModel.filterGenres()
                libraryModel.populate()
                loading.visible = false
                griloModel.loaded = true
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

        onCountChanged: {
            if (argFile === model.get(count - 1).file)
            {
                trackQueue.model.clear();
                trackQueue.model.append(model.get(count - 1));
                trackClicked(trackQueue, 0, true);
            }
        }
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
        id: recentModel
    }
    LibraryListModel {
        id: recentAlbumTracksModel
    }
    LibraryListModel {
        id: recentPlaylistTracksModel
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

    // Blurred background
    BlurredBackground {
    }

    LoadingSpinnerComponent {
        id:loading
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
                             PopupUtils.close(dialogueNewPlaylist)
                         }
                         else {
                             console.debug("Debug: Something went wrong: "+newList)
                             newplaylistoutput.visible = true
                             newplaylistoutput.text = i18n.tr("Error: "+newList)
                         }
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

    MusicToolbar {
        id: musicToolbar
        objectName: "musicToolbarObject"
        z: 200  // put on top of everything else

        property bool animating: false
        property bool opened: false
    }

    PageStack {
        id: pageStack
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
                property bool populated: false
                id: artistsTab
                objectName: "artiststab"
                anchors.fill: parent
                title: i18n.tr("Artists")
                onVisibleChanged: {
                    if (visible && !populated && griloModel.loaded) {
                        artistModel.filterArtists()
                        populated = true
                    }
                }

                // tab content
                page: MusicArtists {
                    id: musicArtistsPage
                }
            }

            // third tab is albums
            Tab {
                property bool populated: false
                id: albumsTab
                objectName: "albumstab"
                anchors.fill: parent
                title: i18n.tr("Albums")
                onVisibleChanged: {
                    if (visible && !populated && griloModel.loaded) {
                        albumModel.filterAlbums()
                        populated = true
                    }
                }

                // Tab content begins here
                page: MusicAlbums {
                    id: musicAlbumsPage
                }
            }

            // fourth tab is all songs
            Tab {
                property bool populated: false
                id: tracksTab
                objectName: "trackstab"
                anchors.fill: parent
                title: i18n.tr("Songs")
                // TODO: offloading this revents file arguments from working
                /* onVisibleChanged: {
                    if (visible && !populated && griloModel.loaded) {
                        libraryModel.populate()
                        populated = true
                    }
                } */

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

            function getCurrentTab()
            {
                musicToolbar.currentTab = selectedTab;
            }

            onSelectedTabChanged: {
                getCurrentTab();
            }
        } // end of tabs
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
        visible: griloModel.count === 0 && griloModel.loaded === true

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            color: styleMusic.libraryEmpty.labelColor
            fontSize: "medium"
            text: "Please import music and restart the app"
        }

    }

} // end of main view
