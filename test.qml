import QtQuick 2.0
import Ubuntu.Components 0.1
import QtMultimedia 5.0

MainView {
    objectName: "mainView"
    applicationName: "xkcd"
    width: units.gu(100)
    height: units.gu(75)

    function getRandomInt (min, max) {
       return Math.floor(Math.random() * (max - min + 1)) + min;
    }

    Label {
        anchors.top: parent
        anchors.left: parent.left
        anchors.margins: 20
        id: title
        ItemStyle.class: "title"
        text: "XKCD"
    }

    Rectangle {
        anchors.top: title.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: random.top
        anchors.margins: 20
        anchors.bottomMargin: 40
        Image {
        anchors.centerIn: parent
        id: image
        source: "load_message.png"
        }
    }

    Button {
        id: random
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.margins: 40
        objectName: "button"
        text: "Random"
        onClicked: {
            image.source = "loading.png"
            var doc = new XMLHttpRequest();
            doc.onreadystatechange = function() {
            if (doc.readyState == XMLHttpRequest.DONE) {
                    var jsonString = doc.responseText
                    var json = eval('(' + jsonString + ')')
                    image.source = json.img
                }
            }
        doc.open("GET", "http://xkcd.com/" + getRandomInt(0,1000) + "/info.0.json");
        doc.send();
        }
    }
}
