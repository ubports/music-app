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

    // Global keyboard shortcuts
    focus: true
    Keys.onPressed: {
        if (event.key === Qt.Key_Alt) {
            // On alt key press show toolbar and start autohide timer
            musicToolbar.showToolbar();
        }
    }

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
        id: searchAction
        text: i18n.tr("Search")
        keywords: i18n.tr("Search Track")
        onTriggered: PopupUtils.open(Qt.resolvedUrl("MusicSearch.qml"), mainView,
                     {
                                         title: i18n.tr("Search")
                     } )
    }
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

    actions: [searchAction, nextAction, playsAction, prevAction, stopAction, backAction, settingsAction, quitAction]

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
                var index = -1;

                for (var j=0; j < griloModel.count; j++)
                {
                    if (griloModel.get(j).url.toString() == file)
                    {
                        index = j;
                    }
                }

                if (index <= -1) {
                    console.debug("Unknown file " + file + ", skipping")
                    continue
                }

                // enqueue
                var media = griloModel.get(index);
                trackQueue.model.append({"title": media.title, "artist": media.artist, "file": file, "album": media.album, "cover": media.thumbnail.toString(), "genre": media.genre})

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
        // TRANSLATORS: this refers to a number of songs greater than one. The actual number will be prepended to the string automatically (plural forms are not yet fully supported in usermetrics, the library that displays that string)
        format: "<b>%1</b> " + i18n.tr("songs played today")
        emptyFormat: i18n.tr("No songs played today")
        domain: "com.ubuntu.music"
    }

    // Design stuff
    Style { id: styleMusic }
    width: units.gu(100)
    height: units.gu(80)

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
        //Library.reset()
        Library.initialize();

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

        // show toolbar hint at startup
        musicToolbar.showToolbar();
    }


    // VARIABLES
    property string musicName: i18n.tr("Music")
    property string appVersion: '1.1'
    property bool isPlaying: false
    property bool songCounted: false
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
    property bool toolbarShown: musicToolbar.shown
    signal collapseExpand(int index);
    signal collapseSwipeDelete(int index);
    signal onPlayingTrackChange(string source)
    signal onToolbarShownChanged(bool shown, var currentPage, var currentTab)

    property bool wideAspect: width >= units.gu(70)

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

        // Reset the songCounted property to false since this is a new track
        songCounted = false

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
                if (musicToolbar.currentPage == nowPlaying) {
                    player.pause()
                } else { // We are not on the now playing page
                    // Show the Now Playing page and make sure the track is visible
                    nowPlaying.visible = true;
                    nowPlaying.ensureVisibleIndex = index;

                    musicToolbar.showToolbar();
                }
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

        // Reset the songCounted property to false since this is a new track
        songCounted = false

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

            // Increment song count on Welcome screen if song has been playing for over 10 seconds.
            if (player.position > 10000 && !songCounted) {
                songCounted = true
                songsMetric.increment()
            }

            positionChange(position, duration)
        }

        onPlaybackStateChanged: {
            mainView.isPlaying = player.playbackState === MediaPlayer.PlayingState
            QtPowerd.keepAlive = mainView.isPlaying
            console.log("mainView.isPlaying=" + mainView.isPlaying + ", QtPowerd.keepAlive=" + QtPowerd.keepAlive)
        }
    }

    SongsSheet {
        id: songsSheet
    }

    AlbumsSheet {
        id: artistSheet
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

            /* Check if the file (needle) exists in the library (haystack)
             * Searches the the haystack using a binary search
             *
             * false if the file in in grilo but not in the haystack
             * positive if the file is the same (number is the actual index)
             * negative if the file has changed, actual index is -(i + 1)
             */
            function exists(haystack, needle)
            {
                var keyToFind = needle["file"];

                var upper = haystack.length - 1;
                var lower = 0;
                var i = Math.floor(haystack.length / 2);

                while (upper >= lower)
                {
                    var key = haystack[i]["file"];

                    if (keyToFind < key)
                    {
                        upper = i - 1;
                    }
                    else if (keyToFind > key)
                    {
                        lower = i + 1;
                    }
                    else
                    {
                        var found = false;

                        for (var k in haystack[i])
                        {
                            if (haystack[i][k] === needle[k])
                            {
                                found = true;
                            }
                            else
                            {
                                found = false;
                                break;
                            }
                        }

                        if (found === true)
                        {
                            return i;  // in grilo and lib - same
                        }
                        else
                        {
                            return -i - 1;  // in grilo and lib - different
                        }
                    }

                    i = Math.floor((upper + lower) / 2);
                }

                return false;  // in grilo not in lib
            }

            onFinished: {
                var currentLibrary = Library.getAllFileOrder();
                var read_arg = false;

                // FIXME: remove when grilo is fixed
                var files = [];
                var duplicates = 0;

                for (var i = 0; i < griloModel.count; i++)
                {
                    var media = griloModel.get(i)
                    var file = media.url.toString()
                    if (file.indexOf("file://") === 0)
                    {
                        file = file.slice(7, file.length)
                    }

                    // FIXME: grilo can supply duplicates
                    if (files.indexOf(file) > -1)
                    {
                        duplicates++;
                        continue;
                    }
                    files.push(file);

                    var record = {
                        artist: media.artist || i18n.tr("Unknown Artist"),
                        album: media.album || i18n.tr("Unknown Album"),
                        title: media.title || file,
                        file: file,
                        cover: media.thumbnail.toString(),
                        length: media.duration.toString(),
                        number: media.trackNumber,
                        year: media.year.toString() !== "0" ? media.year.toString(): i18n.tr("Unknown Year"),
                        genre: media.genre || i18n.tr("Unknown Genre")
                    };

                    if (read_arg === false && argFile === file)
                    {
                        trackQueue.model.clear();
                        trackQueue.model.append(record)
                        trackClicked(trackQueue, 0, true);

                        // grilo model sometimes has duplicates
                        // causing the track to be paused the second time
                        // this ignores the second time
                        read_arg = true;
                    }

                    // Only write to database if the record has actually changed
                    var index = exists(currentLibrary, record);

                    if (index === false || index < 0)  // in grilo !in lib or lib out of date
                    {
                        //console.log("Artist:"+ media.artist + ", Album:"+media.album + ", Title:"+media.title + ", File:"+file + ", Cover:"+media.thumbnail + ", Number:"+media.trackNumber + ", Genre:"+media.genre);
                        Library.setMetadata(record)

                        if (index < 0)
                        {
                            index = -(index + 1);
                        }
                    }

                    if (index !== false)
                    {
                        currentLibrary.splice(index, 1);
                    }
                }

                Library.writeDb()

                // Any items left in currentLibrary aren't in the grilo model so have been deleted
                if (currentLibrary.length > 0)
                {
                    console.debug("Removing deleted songs:", currentLibrary.length);
                    Library.removeFiles(currentLibrary);
                }

                console.debug("Grilo duplicates:", duplicates);  // FIXME: remove when grilo is fixed
                griloModel.loaded = true
                tabs.ensurePopulated(tabs.selectedTab);
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
        onPreLoadCompleteChanged: {
            if (preLoadComplete)
            {
                loading.visible = false
                tracksTab.loading = false
                tracksTab.populated = true
            }
        }
    }

    LibraryListModel {
        id: artistModel
        onPreLoadCompleteChanged: {
            if (preLoadComplete)
            {
                loading.visible = false
                artistsTab.loading = false
                artistsTab.populated = true
            }
        }
    }
    LibraryListModel {
        id: artistTracksModel
    }
    LibraryListModel {
        id: artistAlbumsModel
    }

    LibraryListModel {
        id: albumModel
        onPreLoadCompleteChanged: {
            if (preLoadComplete)
            {
                loading.visible = false
                albumsTab.loading = false
                albumsTab.populated = true
            }
        }
    }
    LibraryListModel {
        id: albumTracksModel
    }

    LibraryListModel {
        id: recentModel
        property bool complete: false
        onPreLoadCompleteChanged: {
            complete = true;

            if (preLoadComplete && (genreModel.complete ||
                                    genreModel.query().length === 0))
            {
                loading.visible = false
                startTab.loading = false
                startTab.populated = true
            }
        }
    }
    LibraryListModel {
        id: recentAlbumTracksModel
    }
    LibraryListModel {
        id: recentPlaylistTracksModel
    }

    LibraryListModel {
        id: genreModel
        property bool complete: false
        onPreLoadCompleteChanged: {
            complete = true;

            if (preLoadComplete && (recentModel.complete ||
                                    recentModel.query().length === 0))
            {
                loading.visible = false
                startTab.loading = false
                startTab.populated = true
            }
        }
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
    LibraryListModel {
        id: playlistModel

        onPreLoadCompleteChanged: {
            if (preLoadComplete)
            {
                loading.visible = false
                playlistTab.loading = false
                playlistTab.populated = true
            }
        }
    }

    // search model
    LibraryListModel {
        id: searchModel
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
                objectName: "playlistnameTextfield"
                placeholderText: i18n.tr("Name")
            }
            ListItem.Standard {
                id: newplaylistoutput
                visible: false // should only be visible when an error is made.
            }

            Button {
                text: i18n.tr("Create")
                objectName: "newPlaylistDialog_createButton"
                onClicked: {
                    newplaylistoutput.visible = false // make sure its hidden now if there was an error last time
                    if (playlistName.text.length > 0) { // make sure something is acually inputed
                        var newList = Playlists.addPlaylist(playlistName.text)
                        if (newList === "OK") {
                            console.debug("Debug: User created a new playlist named: "+playlistName.text)
                            // add the new playlist to the tab
                            var index = Playlists.getID(); // get the latest ID
                            playlistModel.model.append({"id": index, "name": playlistName.text, "count": "0"})
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
            anchors {
                bottomMargin: wideAspect ? musicToolbar.fullHeight : undefined
                fill: parent
            }

            // First tab is all music
            Tab {
                property bool populated: false
                property var loader: [recentModel.filterRecent, genreModel.filterGenres]
                property bool loading: false
                property var model: [recentModel, genreModel, albumTracksModel]
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
                property var loader: [artistModel.filterArtists]
                property bool loading: false
                property var model: [artistModel, artistAlbumsModel, albumTracksModel]
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
                property bool populated: false
                property var loader: [albumModel.filterAlbums]
                property bool loading: false
                property var model: [albumModel, albumTracksModel]
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
                property bool populated: false
                property var loader: [libraryModel.populate]
                property bool loading: false
                property var model: [libraryModel]
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
                property bool populated: false
                property var loader: [playlistModel.filterPlaylists]
                property bool loading: false
                property var model: [playlistModel, albumTracksModel]
                id: playlistTab
                objectName: "playlisttab"
                anchors.fill: parent
                title: i18n.tr("Playlists")

                // Tab content begins here
                page: MusicPlaylists {
                    id: musicPlaylistPage
                }
            }

            // Set the models in the tab to allow/disallow loading
            function allowLoading(tabToLoad, state)
            {
                if (tabToLoad.model !== undefined)
                {
                    for (var i=0; i < tabToLoad.model.length; i++)
                    {
                        tabToLoad.model[i].canLoad = state;
                    }
                }
            }

            function ensurePopulated(selectedTab)
            {
                allowLoading(selectedTab, true);  // allow loading of the models

                if (!selectedTab.populated && !selectedTab.loading && griloModel.loaded) {
                    loading.visible = true
                    selectedTab.loading = true

                    if (selectedTab.loader !== undefined)
                    {
                        for (var i=0; i < selectedTab.loader.length; i++)
                        {
                            selectedTab.loader[i]();
                        }
                    }
                }
                loading.visible = selectedTab.loading || !selectedTab.populated
            }

            onSelectedTabChanged: {
                // pause loading of the models in the old tab
                if (musicToolbar.currentTab !== selectedTab &&
                        musicToolbar.currentTab !== null)
                {
                    allowLoading(musicToolbar.currentTab, false);
                }

                musicToolbar.currentTab = selectedTab;

                ensurePopulated(selectedTab);
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
