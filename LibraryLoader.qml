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
import "settings.js" as Settings
import "meta-database.js" as Library
import "playing-list.js" as PlayingList

Page {
    anchors.fill: parent

    tools: ToolbarActions {
        lock: true
        active: true
        Action {
            itemHint: Button {
                id: goUp
                width: units.gu(10)
                text: "Go up"
                onClicked: {
                    folderModel.path = folderModel.parentPath
                    currentpath.text = folderModel.path
                }
            }
        }

        Action {
            itemHint: Button {
                id: selectDirectory
                width: units.gu(10)
                text: "Select"
                color: "#DD4814"
                onClicked: {
                    player.stop()
                    Library.reset()
                    Library.initialize()
                    Settings.setSetting("currentfolder", folderModel.path)
                    folderScannerModel.path = folderModel.path
                    timer.start()
                }
            }
        }

        back {
            itemHint: Button {
                id: cancelButton
                width: units.gu(10)
                text: "Cancel"
                onClicked: {
                    pageStack.pop()
                }
            }
        }
    }

    Timer {
        id: timer
        interval: 200; repeat: true
        running: false
        triggeredOnStart: true
        property int counted: 0

        onTriggered: {
            console.log("Counted: " + counted)
            console.log("filelist.count: " + filelist.count)
            if (counted === filelist.count) {
                pageStack.pop()
                console.log("MOVING ON")
                libraryModel.populate()
                PlayingList.clear()
                itemnum = 0
                folderScannerModel.path = ""
                timer.stop()
            }
            counted = filelist.count
        }
    }

    ListView {
        id: folderSelecterList
        anchors.fill: parent
        anchors.topMargin: units.gu(3)

        model: folderModel
        delegate: folderSelecterDelegate

        Component {
            id: folderSelecterDelegate
            ListItem.Standard {
                id: file
                progression: model.isDir
                icon: !model.isDir ? (trackCover === "" ? (fileName.match("\\.mp3") ? Qt.resolvedUrl("images/audio-x-mpeg.png") : Qt.resolvedUrl("images/audio-x-vorbis+ogg.png")) : "image://cover-art/"+filePath) : Qt.resolvedUrl("images/folder.png")
                iconFrame: false
                Label {
                    id: fileTitle
                    width: 400
                    wrapMode: Text.Wrap
                    maximumLineCount: 1
                    font.pixelSize: 16
                    anchors.left: parent.left
                    anchors.leftMargin: 75
                    anchors.top: parent.top
                    anchors.topMargin: 5
                    text: trackTitle == "" ? fileName : trackTitle
                }
                Label {
                    id: fileArtistAlbum
                    width: 400
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    font.pixelSize: 12
                    anchors.left: parent.left
                    anchors.leftMargin: 75
                    anchors.top: fileTitle.bottom
                    text: trackArtist == "" ? "" : trackArtist + " - " + trackAlbum
                }
                Label {
                    id: fileDuration
                    width: 400
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    font.pixelSize: 12
                    anchors.left: parent.left
                    anchors.leftMargin: 75
                    anchors.top: fileArtistAlbum.bottom
                    visible: false
                    text: ""
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        if (model.isDir) {
                            currentpath.text = filePath
                            folderModel.path = filePath
                        }
                    }
                }
            }
        }
    }

    Column {
        Repeater {
            id: filelist
            width: parent.width
            height: parent.height - units.gu(8)
            anchors.top: tracksContext.bottom
            model: folderScannerModel
            onCountChanged: {
                filelistCount = filelist.count
            }
            Component {
                id: fileScannerDelegate
                Rectangle {
                    Component.onCompleted: {
                        if (!model.isDir) {
                            console.log("Scanner fileDelegate onComplete")
                            Library.setMetadata(filePath, trackTitle, trackArtist, trackAlbum, "image://cover-art/" + filePath, trackYear, trackNumber, trackLength)
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        width: parent.width
        height: units.gu(3)
        Label {
            id: currentpath
            text: folderModel.path
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 10
            font.pixelSize: 12
        }
    }
}



