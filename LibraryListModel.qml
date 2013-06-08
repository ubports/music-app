import QtQuick 2.0
import QtQuick.LocalStorage 2.0
import "meta-database.js" as Library

Item {
    property ListModel model : ListModel { id: libraryModel }
    property alias count: libraryModel.count

    function populate() {
        libraryModel.clear();
        console.log("called LibraryListModel::populate()")

        var library = Library.getAll()

        for ( var key in library ) {
            var add = library[key];
            console.log(JSON.stringify(add))
            libraryModel.append( add );
        }
    }

    function filterArtists() {
        libraryModel.clear();
        console.log("called LibraryListModel::filterArtists()")

        var library = Library.getAll()

        var added = new Array
        for ( var key in library ) {
            var add = library[key];
            console.log("add.artist: "+add.artist)
            console.log(JSON.stringify(add))
            if (added.indexOf(add.artist) === -1) {
                libraryModel.append( add );
                added.push(add.artist)
            }
        }
    }

    function filterAlbums() {
        libraryModel.clear();
        console.log("called LibraryListModel::filterAlbums()")

        var library = Library.getAll()

        var added = new Array
        for ( var key in library ) {
            var add = library[key];
            console.log("add.album: "+add.album)
            console.log(JSON.stringify(add))
            if (added.indexOf(add.album) === -1) {
                libraryModel.append( add );
                added.push(add.album)
            }
        }
    }
}
