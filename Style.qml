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


QtObject {
    property QtObject common: QtObject {
        property color black: "#000000";
        property color white: "#FFFFFF";
    }

    property QtObject dialog: QtObject {
        property color buttonColor: UbuntuColors.coolGrey;
    }

    property QtObject libraryEmpty: QtObject {
        property color backgroundColor: UbuntuColors.coolGrey;
        property color labelColor: common.white;
    }

    property QtObject listView: QtObject {
        property color highlightColor: common.white;
    }

    property QtObject mainView: QtObject{
        property color backgroundColor: "#A55263";
        property color footerColor: "#D75669";
        property color headerColor: "#57365E";
    }

    property QtObject nowPlaying: QtObject {
        property color backgroundColor: UbuntuColors.coolGrey;
        property color labelColor: common.white;
        property color labelSecondaryColor: "#AAA";
        property color progressBackgroundColor: common.black;
        property color progressForegroundColor: UbuntuColors.orange;
        property color progressHandleColor: common.white;
    }

    property QtObject playerControls: QtObject {
        property color backgroundColor: UbuntuColors.coolGrey;
        property color labelColor: common.white;
        property color progressBackgroundColor: common.black;
        property color progressForegroundColor: UbuntuColors.orange;
    }

    property QtObject popover: QtObject {
        property color labelColor: UbuntuColors.coolGrey;
    }

    property QtObject addtoPlaylist: QtObject {
        property color backgroundColor: UbuntuColors.coolGrey;
        property color labelColor: common.white;
        property color labelSecondaryColor: "#AAA";
        property color progressBackgroundColor: common.black;
        property color progressForegroundColor: UbuntuColors.orange;
        property color progressHandleColor: common.white;
    }

    property QtObject musicSettings: QtObject {
        property color labelColor: UbuntuColors.coolGrey;
    }
}
