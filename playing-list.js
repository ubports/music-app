//playing-list.js
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
