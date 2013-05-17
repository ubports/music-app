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
//import Qt.labs.folderlistmodel 1.0 // change from this
import org.nemomobile.folderlistmodel 1.0 //change to this
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0


PageStack {
    id: singleTracksPageStack
    anchors.fill: parent

//    property int  headerHeight:  units.gu(10); // needed?

    width: units.gu(50)
    height: units.gu(75)

    // set the folder from where the music is
    FolderListModel {
        id: folderModel
        path: homePath()+"/Musik/"
        showDirectories: false
        nameFilters: ["*.ogg","*.mp3","*.oga","*.wav"]
    }

    Page {
        id: singleTracksPage

        // toolbar
        tools: defaultToolbar

        ListView {
            id: singeTrackList
            width: units.gu(40)
            height: units.gu(50)
            model: folderModel
            delegate: ListItem.Standard {
                //text: artist+" - "+title
                id: file
                text: fileName
            }
        }

    }

}
