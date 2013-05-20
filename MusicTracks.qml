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
import "settings.js" as Settings
import "meta-database.js" as MetaDB


PageStack {
    id: singleTracksPageStack
    anchors.fill: parent

    Component.onCompleted: {
        // initialize settings db
        Settings.initialize()
        console.debug("INITIALIZED Settings")
        if (Settings.getSetting("initialized") !== "true") {
            // initialize settings
            console.debug("reset settings")
            Settings.setSetting("initialized", "true")
            Settings.setSetting("currentfolder", "/")
        }
        else {
            musicDir = Settings.getSetting("currentfolder")
            console.debug("Debug: Music dir set to: "+Settings.getSetting("currentfolder"))
        }

        // then go on to meta data db
        MetaDB.initialize()
        console.debug("INITIALIZED Meta data")
        /*
        if (MetaDB.getSetting("initialized") !== "true") {
            // start adding tracks to db
            title = getTrackInfo(file, title)
            album = getTrackInfo(file, album)
            year = getTrackInfo(file, year)
            tracknr = getTrackInfo(file, tracknr)
            length = getTrackInfo(file, length)
            console.debug("file", "title", "artist", "album", "year", "tracknr", "length")
            //MetaDB.setSetting("file", "title", "artist", "album", "year", "tracknr", "length")
        }*/
    }


    width: units.gu(50)
    height: units.gu(75)

    // set the folder from where the music is
    FolderListModel {
        id: folderModel
        folder: musicDir
        showDirs: false
        nameFilters: ["*.ogg","*.mp3","*.oga","*.wav"]
    }

    Page {
        id: singleTracksPage

        // toolbar
        tools: defaultToolbar

        Column {
            anchors.centerIn: parent
            anchors.fill: parent
            ListView {
                id: musicFolder
                width: parent.width
                height: parent.height
                model: folderModel
                //delegate: databaseDelegate
                delegate: ListItem.Subtitled {
                    text: fileName
                    subText: "Artist: "
                    onClicked: {
                        playMusic.source = filePath
                        playMusic.play()
                        console.debug('Debug: User pressed '+filePath)
                        trackInfo.text = playMusic.metaData.albumArtist+" - "+playMusic.metaData.title // show track meta data
                        // cool animation
                    }
                    onPressAndHold: {
                        console.debug('Debug: '+fileName+' added to queue.')
                        trackQueue.append({"title": playMusic.metaData.title, "artist": playMusic.metaData.albumArtist, "file": fileName})
                        // cool animation
                    }
                }
            }
        }

    }

}
