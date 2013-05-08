tools: ToolbarActions {
    // Share
    Action {
        objectName: "share"

        iconSource: Qt.resolvedUrl("images/icon_share@20.png")
        text: i18n.tr("Share")

        onTriggered: {
            console.debug('Debug: Share pressed')
        }
    }

    // prevous track
    Action {
        objectName: "prev"

        iconSource: Qt.resolvedUrl("images/prev.png")
        text: i18n.tr("Previous")

        onTriggered: {
            console.debug('Debug: Prev track pressed')
        }
    }

    // Play or pause
    Action {
        objectName: "plaus"

        iconSource: Qt.resolvedUrl("images/icon_play@20.png")
        text: i18n.tr("Play")

        onTriggered: {
            console.debug('Debug: Play pressed')
            // should also change button to pause icon
            plaus.iconSource = Qt.resolvedUrl("images/icon_pause@20.png")
        }
    }

    // Next track
    Action {
        objectName: "next"

        iconSource: Qt.resolvedUrl("images/next.png")
        text: i18n.tr("Next")

        onTriggered: {
            console.debug('Debug: next track pressed')
        }
    }

    // Settings
    Action {
        objectName: "settings"

        iconSource: Qt.resolvedUrl("images/icon_settings@20.png")
        text: i18n.tr("Settings")

        onTriggered: {
            console.debug('Debug: Settings pressed')
            // show settings page
            pageStack.push(Qt.resolvedUrl("MusicSettings.qml")) // resolce pageStack issue
        }
    }
}
