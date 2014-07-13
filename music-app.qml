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

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1
import Ubuntu.Components.Popups 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Content 0.1 as ContentHub
import Ubuntu.MediaScanner 0.1
import Ubuntu.Unity.Action 1.0 as UnityActions
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
    useDeprecatedToolbar: false

    // Use toolbar color for header
    headerColor: styleMusic.toolbar.fullBackgroundColor
    backgroundColor: styleMusic.toolbar.fullBackgroundColor

    // Global keyboard shortcuts
    focus: true
    Keys.onPressed: {
        if (event.key === Qt.Key_Alt) {
            // On alt key press show toolbar and start autohide timer
            musicToolbar.showToolbar();
        }
        else if(event.key === Qt.Key_Escape) {
            musicToolbar.goBack();  // Esc      Go back
        }
        else if(event.modifiers === Qt.AltModifier) {
            var position;

            switch (event.key) {
            case Qt.Key_Right:  //  Alt+Right   Seek forward +10secs
                position = player.position + 10000 < player.duration
                        ? player.position + 10000 : player.duration;
                player.seek(position);
                break;
            case Qt.Key_Left:  //   Alt+Left    Seek backwards -10secs
                position = player.position - 10000 > 0
                        ? player.position - 10000 : 0;
                player.seek(position);
                break;
            }
        }
        else if(event.modifiers === Qt.ControlModifier) {
            switch (event.key) {
            case Qt.Key_Left:   //  Ctrl+Left   Previous Song
                player.previousSong(true);
                break;
            case Qt.Key_Right:  //  Ctrl+Right  Next Song
                player.nextSong(true, true);
                break;
            case Qt.Key_Up:  //     Ctrl+Up     Volume up
                player.volume = player.volume + .1 > 1 ? 1 : player.volume + .1
                break;
            case Qt.Key_Down:  //   Ctrl+Down   Volume down
                player.volume = player.volume - .1 < 0 ? 0 : player.volume - .1
                break;
            case Qt.Key_R:  //      Ctrl+R      Repeat toggle
                player.repeat = !player.repeat
                break;
            case Qt.Key_F:  //      Ctrl+F      Show Search popup
                if (!searchSheet.sheetVisible) {
                    PopupUtils.open(searchSheet.sheet, mainView,
                                    { title: i18n.tr("Search") })
                }
                break;
            case Qt.Key_J:  //      Ctrl+J      Jump to playing song
                nowPlaying.visible = true;
                nowPlaying.positionAt(player.currentIndex);
                musicToolbar.showToolbar();
                break;
            case Qt.Key_N:  //      Ctrl+N      Show now playing
                nowPlaying.visible = true;
                musicToolbar.showToolbar();
                break;
            case Qt.Key_P:  //      Ctrl+P      Toggle playing state
                player.toggle();
                break;
            case Qt.Key_Q:  //      Ctrl+Q      Quit the app
                Qt.quit();
                break;
            case Qt.Key_U:  //      Ctrl+U      Shuffle toggle
                player.shuffle = !player.shuffle
                break;
            }
        }
    }

    // Arguments during startup
    Arguments {
        id: args
        //defaultArgument.help: "Expects URI of the track to play." // should be used when bug is resolved
        //defaultArgument.valueNames: ["URI"] // should be used when bug is resolved
        // grab a file
        Argument {
            name: "url"
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
        onTriggered: {
            if (!searchSheet.sheetVisible) {
                PopupUtils.open(searchSheet.sheet, mainView,
                     {
                                         title: i18n.tr("Search")
                     } )
            }
        }
    }
    Action {
        id: nextAction
        text: i18n.tr("Next")
        keywords: i18n.tr("Next Track")
        onTriggered: player.nextSong()
    }
    Action {
        id: playsAction
        text: player.playbackState === MediaPlayer.PlayingState ?
                  i18n.tr("Pause") : i18n.tr("Play")
        keywords: player.playbackState === MediaPlayer.PlayingState ?
                      i18n.tr("Pause Playback") : i18n.tr("Continue or start playback")
        onTriggered: player.toggle()
    }
    Action {
        id: backAction
        text: i18n.tr("Back")
        keywords: i18n.tr("Go back to last page")
        onTriggered: musicToolbar.goBack();
    }

    // With a default Quit action only the first 4 actions are displayed
    // until the user searches for them within the HUD
    Action {
        id: prevAction
        text: i18n.tr("Previous")
        keywords: i18n.tr("Previous Track")
        onTriggered: player.previousSong()
    }
    Action {
        id: stopAction
        text: i18n.tr("Stop")
        keywords: i18n.tr("Stop Playback")
        onTriggered: player.stop()
    }

    // TODO: Currently there are no settings, so do not display the Action
    Action {
        id: settingsAction
        text: i18n.tr("Settings")
        keywords: i18n.tr("Music Settings")
        onTriggered: {
            customdebug('Show settings')
            musicSettings.visible = true
        }
    }

    actions: [searchAction, nextAction, playsAction, prevAction, stopAction, backAction]

    // signal to open new URIs
    Connections {
        id: uriHandler
        target: UriHandler

        function processAlbum(uri) {
            var split = uri.split("/");

            if (split.length < 2) {
                console.debug("Unknown artist-album " + uri + ", skipping")
                return;
            }

            // Filter by artist and album
            songsAlbumArtistModel.artist = decodeURIComponent(split[0]);
            songsAlbumArtistModel.album = decodeURIComponent(split[1]);

            // Play album it tracks exist
            if (songsAlbumArtistModel.rowCount > 0) {
                // trackClicked(model, index, play, clear=true) will clear the model
                trackClicked(songsAlbumArtistModel, 0, true, true);
            }
            else {
                console.debug("Unknown artist-album " + uri + ", skipping")
                return;
            }
        }

        function processFile(uri, play) {
            uri = decodeURIComponent(uri);

            var track = false;

            // Search for track in songs model
            for (var i=0; i < allSongsModel.rowCount; i++) {
                if (decodeURIComponent(allSongsModel.get(i, allSongsModel.RoleModelData).filename) === uri) {
                    track = allSongsModel.get(i, allSongsModel.RoleModelData);
                    break;
                }
            }

            if (!track) {
                console.debug("Unknown file " + uri + ", skipping")
                return;
            }

            if (play) {
                // clear play queue
                trackQueue.model.clear()
            }

            // enqueue
            trackQueue.append(makeDict(track));

            // play first URI
            if (play) {
                trackQueueClick(trackQueue.model.count - 1);
            }
        }

        function process(uri, play) {
            if (uri.indexOf("album:///") === 0) {
                uriHandler.processAlbum(uri.substring(9));
            }
            else if (uri.indexOf("file://") === 0) {
                uriHandler.processFile(uri.substring(7), play);
            }
            else if (uri.indexOf("music://") === 0) {
                uriHandler.processFile(uri.substring(8), play);
            }

            else {
                console.debug("Unsupported URI " + uri + ", skipping")
            }
        }

        onOpened: {
            for (var i=0; i < uris.length; i++) {
                console.debug("URI=" + uris[i])

                uriHandler.process(uris[i], i === 0);
            }
        }
    }

    // Content hub support
    Connections {
        target: ContentHub.ContentHub
        onImportRequested: {
            if (transfer.state === ContentHub.ContentTransfer.Charged) {
                for(var i=0; i < transfer.items.length; i++) {
                    uriHandler.process(transfer.items[i].url.toString(), i === 0)
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

    // Connections for usermetrics
    Connections {
        id: userMetricPlayerConnection
        target: player
        property bool songCounted: false

        onSourceChanged: {
            songCounted = false
        }

        onPositionChanged: {
            // Increment song count on Welcome screen if song has been
            // playing for over 10 seconds.
            if (player.position > 10000 && !songCounted) {
                songCounted = true
                songsMetric.increment()
                console.debug("Increment UserMetrics")
            }
        }
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
        Library.initialize();

        // initialize playlists
        Playlists.initializePlaylists()
        Playlists.initializePlaylist()
        // everything else
        loading.visible = true
        scrobble = Settings.getSetting("scrobble") == "1" // scrobble state
        lastfmusername = Settings.getSetting("lastfmusername") // lastfm username
        lastfmpassword = Settings.getSetting("lastfmpassword") // lastfm password

        // push the page to view
        mainPageStack.push(tabs)

        loadedUI = true;

        // TODO: Switch tabs back and forth to get the background color in the
        //       header to work properly.
        tabs.selectedTabIndex = 1
        tabs.selectedTabIndex = 0

        // Run post load
        tabs.ensurePopulated(tabs.selectedTab);

        if (args.values.url) {
            uriHandler.process(args.values.url, true);
        }

        // Show toolbar and start timer if there is music
        if (!emptyPage.noMusic) {
            musicToolbar.showToolbar();
            musicToolbar.startAutohideTimer();
        }
    }

    // VARIABLES
    property string musicName: i18n.tr("Music")
    property string appVersion: '1.2'
    property bool hasRecent: !Library.isRecentEmpty()
    property bool scrobble: false
    property string lastfmusername
    property string lastfmpassword
    property string timestamp // used to scrobble
    property var chosenElement: null
    property bool toolbarShown: musicToolbar.shown
    signal collapseExpand();
    signal collapseSwipeDelete(int index);
    signal onToolbarShownChanged(bool shown, var currentPage, var currentTab)

    property bool wideAspect: width >= units.gu(70)
    property bool loadedUI: false  // property to detect if the UI has finished

    // FUNCTIONS

    // Custom debug funtion that's easier to shut off
    function customdebug(text) {
        var debug = true; // set to "0" for not debugging
        //if (args.values.debug) { // *USE LATER*
        if (debug) {
            console.debug(i18n.tr("Debug: ")+text);
        }
    }

    function addQueueFromModel(model)
    {
        // TODO: remove once playlists uses U1DB
        if (model.hasOwnProperty("linkLibraryListModel")) {
            model = model.linkLibraryListModel;
        }

        for (var i=0; i < model.rowCount; i++) {
            trackQueue.model.append(makeDict(model.get(i, model.RoleModelData)));
        }
    }

    // Converts an duration in ms to a formated string ("minutes:seconds")
    function durationToString(duration) {
        var minutes = Math.floor((duration/1000) / 60);
        var seconds = Math.floor((duration/1000)) % 60;
        // Make sure that we never see "NaN:NaN"
        if (minutes.toString() == 'NaN')
            minutes = 0;
        if (seconds.toString() == 'NaN')
            seconds = 0;
        return minutes + ":" + (seconds<10 ? "0"+seconds : seconds);
    }

    // Make dictionary from model item
    function makeDict(model) {
        return {
            album: model.album,
            art: "image://albumart/artist=" + model.author + "&album=" + model.album,
            author: model.author,
            filename: model.filename,
            title: model.title
        };
    }

    function trackClicked(model, index, play, clear) {
        // TODO: remove once playlists uses U1DB
        if (model.hasOwnProperty("linkLibraryListModel")) {
            model = model.linkLibraryListModel;
        }

        var file = Qt.resolvedUrl(model.get(index, model.RoleModelData).filename);

        play = play === undefined ? true : play  // default play to true
        clear = clear === undefined ? false : clear  // force clear and will ignore player.toggle()

        if (!clear) {
            // If same track and on now playing page then toggle
            if (musicToolbar.currentPage === nowPlaying &&
                    trackQueue.model.get(player.currentIndex) !== undefined &&
                    Qt.resolvedUrl(trackQueue.model.get(player.currentIndex).filename) === file) {
                player.toggle()
                return;
            }
        }

        trackQueue.model.clear();  // clear the old model

        addQueueFromModel(model);

        if (play) {
            player.playSong(file, index);

            // Show the Now Playing page and make sure the track is visible
            tabs.pushNowPlaying();
            nowPlaying.ensureVisibleIndex = index;

            musicToolbar.showToolbar();
        }
        else {
            player.source = file;
        }

        collapseExpand();  // collapse all expands if track clicked
    }

    function trackQueueClick(index) {
        if (player.currentIndex === index) {
            player.toggle();
        }
        else {
            player.playSong(trackQueue.model.get(index).filename, index);
        }

        // Show the Now Playing page and make sure the track is visible
        tabs.pushNowPlaying();
        nowPlaying.ensureVisibleIndex = index;

        musicToolbar.showToolbar();
    }

    function playRandomSong(shuffle)
    {
        trackQueue.model.clear();

        var now = new Date();
        var seed = now.getSeconds();
        var index = Math.floor(allSongsModel.rowCount * Math.random(seed));

        player.shuffle = shuffle === undefined ? true : shuffle;

        trackClicked(allSongsModel, index, true)
    }

    // Load mediascanner store
    MediaStore {
        id: musicStore
    }

    SongsModel {
        id: allSongsModel
        store: musicStore
    }

    SongsModel {
        id: songsAlbumArtistModel
        store: musicStore
    }

    // WHERE THE MAGIC HAPPENS
    Player {
        id: player
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

    // TODO: Used by playlisttracks move to U1DB
    LibraryListModel {
        id: albumTracksModel
    }

    // TODO: used by recent items move to U1DB
    LibraryListModel {
        id: recentModel
        property bool complete: false
        onPreLoadCompleteChanged: {
            complete = true;

            if (preLoadComplete)
            {
                loading.visible = false
                startTab.loading = false
                startTab.populated = true
            }
        }
    }

    // TODO: used by recent albums move to U1DB
    LibraryListModel {
        id: recentAlbumTracksModel
    }

    // TODO: used by recent playlists move to U1DB
    LibraryListModel {
        id: recentPlaylistTracksModel
    }

    // list of tracks on startup. This is just during development
    LibraryListModel {
        id: trackQueue

        function append(listElement)
        {
            model.append(makeDict(listElement))
            console.debug(JSON.stringify(makeDict(listElement)));
        }
    }

    // TODO: list of playlists move to U1DB
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

    // load sheets (after model)
    MusicSearch {
        id: searchSheet
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
                        console.debug("Debug: Add track to queue: " + JSON.stringify(chosenElement))
                        PopupUtils.close(trackPopover)
                        trackQueue.append(chosenElement)
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

                        mainPageStack.push(addtoPlaylist)
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
            Label {
                id: newplaylistoutput
                color: "white"
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
    }

    Page {
        id: emptyPage
        title: i18n.tr("Music")
        visible: false

        property bool noMusic: allSongsModel.rowCount === 0 && loadedUI

        onNoMusicChanged: {
            if (noMusic)
                mainPageStack.push(emptyPage)
            else if (pageStack.currentPage == emptyPage)
                mainPageStack.pop()
        }

        tools: ToolbarItems {
            back: null
            locked: true
            opened: false
        }

        // Overlay to show when no tracks detected on the device
        Rectangle {
            id: libraryEmpty
            anchors.fill: parent
            anchors.topMargin: -emptyPage.header.height
            color: styleMusic.libraryEmpty.backgroundColor

            Column {
                anchors.centerIn: parent

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: styleMusic.libraryEmpty.labelColor
                    fontSize: "large"
                    font.bold: true
                    text: "No music found"
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: styleMusic.libraryEmpty.labelColor
                    fontSize: "medium"
                    text: "Please import music and restart the app"
                }
            }
        }
    }

    PageStack {
        id: mainPageStack

        Tabs {
            id: tabs
            anchors {
                bottomMargin: wideAspect ? musicToolbar.fullHeight : undefined
                fill: parent
            }

            // First tab is all music
            Tab {
                property bool populated: false
                property var loader: [recentModel.filterRecent]
                property bool loading: false
                property var model: [recentModel, albumTracksModel]
                id: startTab
                objectName: "starttab"
                anchors.fill: parent
                title: page.title

                // Tab content begins here
                page: MusicStart {
                    id: musicStartPage
                }
            }

            // Second tab is arists
            Tab {
                property bool populated: true
                property var loader: []
                property bool loading: false
                property var model: []
                id: artistsTab
                objectName: "artiststab"
                anchors.fill: parent
                title: page.title

                // tab content
                page: MusicArtists {
                    id: musicArtistsPage
                }
            }

            // third tab is albums
            Tab {
                property bool populated: true
                property var loader: []
                property bool loading: false
                property var model: []
                id: albumsTab
                objectName: "albumstab"
                anchors.fill: parent
                title: page.title

                // Tab content begins here
                page: MusicAlbums {
                    id: musicAlbumsPage
                }
            }

            // fourth tab is all songs
            Tab {
                property bool populated: true
                property var loader: []
                property bool loading: false
                property var model: []
                id: tracksTab
                objectName: "trackstab"
                anchors.fill: parent
                title: page.title

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
                title: page.title

                // Tab content begins here
                page: MusicPlaylists {
                    id: musicPlaylistPage
                }
            }

            // Set the models in the tab to allow/disallow loading
            function allowLoading(tabToLoad, state)
            {
                if (tabToLoad !== undefined && tabToLoad.model !== undefined)
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

                if (!selectedTab.populated && !selectedTab.loading && loadedUI) {
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

            function pushNowPlaying()
            {
                // only push if on a different page
                if (mainPageStack.currentPage !== nowPlaying) {
                    mainPageStack.push(nowPlaying);
                }
            }

            Component.onCompleted: musicToolbar.currentTab = selectedTab

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

    SongsPage {
        id: songsPage
    }

    AlbumsPage {
        id: albumsPage
    }

    MusicNowPlaying {
        id: nowPlaying
    }

    MusicaddtoPlaylist {
        id: addtoPlaylist
    }

} // end of main view
