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

.pragma library
var myArray = new Array()
var myLocation = new Array()

function getList() {
    return myArray
}

function at(index) {
    return myLocation[index]
}

function addItem(item, index) {
    myArray.push(item)
    myLocation.push(index)
}

function contains(item) {
    return myArray.indexOf(item) !== -1
}

function indexOf(item) {
    return myArray.indexOf(item)
}

function size() {
    return myArray.length
}

function clear() {
    myArray = []
    myLocation = []
}

function rebuild(currentModel)
{
    console.debug("Clearing playing list")
    clear()

    for (var i=0; i < currentModel.count; i++)
    {
        addItem(currentModel.get(i).file, i)
    }
}
