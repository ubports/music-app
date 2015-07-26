/*
 * Copyright (C) 2012-2015 Canonical, Ltd.
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

import QtQuick 2.4
import Ubuntu.Components 1.2
import Ubuntu.Components.ListItems 1.0 as ListItem


Item {
    id: root
    width: parent.width

    property Action leftSideAction: null
    property list<Action> rightSideActions
    property double defaultHeight: units.gu(8)
    property bool locked: false
    property Action activeAction: null
    property var activeItem: null
    property bool triggerActionOnMouseRelease: false
    property color color: styleMusic.mainView.backgroundColor
    property color selectedColor: "#3d3d45"  // "#E6E6E6"  // CUSTOM
    property bool selected: false
    property bool selectionMode: false
    property alias internalAnchors: mainContents.anchors
    default property alias contents: mainContents.children

    readonly property double actionWidth: units.gu(4)  // CUSTOM 5?
    readonly property double leftActionWidth: units.gu(10)
    readonly property double actionThreshold: actionWidth * 0.4
    readonly property double threshold: 0.4
    readonly property string swipeState: main.x == 0 ? "Normal" : main.x > 0 ? "LeftToRight" : "RightToLeft"
    readonly property alias swipping: mainItemMoving.running
    readonly property bool _showActions: mouseArea.pressed || swipeState != "Normal" || swipping

    property alias _main: main  // CUSTOM
    property alias pressed: mouseArea.pressed  // CUSTOM

    /* internal */
    property var _visibleRightSideActions: filterVisibleActions(rightSideActions)

    signal itemClicked(var mouse)
    signal itemPressAndHold(var mouse)

    function returnToBoundsRTL(direction)
    {
        var actionFullWidth = actionWidth + units.gu(2)

        // go back to normal state if swipping reverse
        if (direction === "LTR") {
            updatePosition(0)
            return
        } else if (!triggerActionOnMouseRelease) {
            updatePosition(-rightActionsView.width + units.gu(2))
            return
        }

        var xOffset = Math.abs(main.x)
        var index = Math.min(Math.floor(xOffset / actionFullWidth), _visibleRightSideActions.length)
        var newX = 0

        if (index === _visibleRightSideActions.length) {
            newX = -(rightActionsView.width - units.gu(2))
        } else if (index >= 1) {
            newX = -(actionFullWidth * index)
        }

        updatePosition(newX)
    }

    function returnToBoundsLTR(direction)
    {
        var finalX = leftActionWidth
        if ((direction === "RTL") || (main.x <= (finalX * root.threshold)))
            finalX = 0
        updatePosition(finalX)
    }

    function returnToBounds(direction)
    {
        if (main.x < 0) {
            returnToBoundsRTL(direction)
        } else if (main.x > 0) {
            returnToBoundsLTR(direction)
        } else {
            updatePosition(0)
        }
    }

    function contains(item, point, marginX)
    {
        var itemStartX = item.x - marginX
        var itemEndX = item.x + item.width + marginX
        return (point.x >= itemStartX) && (point.x <= itemEndX) &&
               (point.y >= item.y) && (point.y <= (item.y + item.height));
    }

    function getActionAt(point)
    {
        if (leftSideAction && contains(leftActionViewLoader.item, point, 0)) {
            return leftSideAction
        } else if (contains(rightActionsView, point, 0)) {
            var newPoint = root.mapToItem(rightActionsView, point.x, point.y)
            for (var i = 0; i < rightActionsRepeater.count; i++) {
                var child = rightActionsRepeater.itemAt(i)
                if (contains(child, newPoint, units.gu(1))) {
                    return i
                }
            }
        }
        return -1
    }

    function updateActiveAction()
    {
        if (triggerActionOnMouseRelease &&
            (main.x <= -(root.actionWidth + units.gu(2))) &&
            (main.x > -(rightActionsView.width - units.gu(2)))) {
            var actionFullWidth = actionWidth + units.gu(2)
            var xOffset = Math.abs(main.x)
            var index = Math.min(Math.floor(xOffset / actionFullWidth), _visibleRightSideActions.length)
            index = index - 1
            if (index > -1) {
                root.activeItem = rightActionsRepeater.itemAt(index)
                root.activeAction = root._visibleRightSideActions[index]
            }
        } else {
            root.activeAction = null
        }
    }

    function resetSwipe()
    {
        updatePosition(0)
    }

    function filterVisibleActions(actions)
    {
        var visibleActions = []
        for(var i = 0; i < actions.length; i++) {
            var action = actions[i]
            if (action.visible) {
                visibleActions.push(action)
            }
        }
        return visibleActions
    }

    function updatePosition(pos)
    {
        if (!root.triggerActionOnMouseRelease && (pos !== 0)) {
            mouseArea.state = pos > 0 ? "RightToLeft" : "LeftToRight"
        } else {
            mouseArea.state = ""
        }
        main.x = pos
    }

    // CUSTOM remove animation
    SequentialAnimation {
        id: removeAnimation

        property var action

        UbuntuNumberAnimation {
            target: root
            duration: UbuntuAnimation.BriskDuration
            property: "height";
            to: 0
        }
        ScriptAction {
            script: removeAnimation.action.trigger()
        }
    }

    states: [
        State {
            name: "select"
            when: selectionMode || selected
            PropertyChanges {
                target: selectionIcon
                source: Qt.resolvedUrl("../ListItemActions/CheckBox.qml")
                anchors.leftMargin: units.gu(2)
            }
            PropertyChanges {
                target: root
                locked: true
            }
            PropertyChanges {
                target: main
                x: 0
            }
        }
    ]

    height: defaultHeight
    //clip: height !== defaultHeight  // CUSTOM

    Loader {  // CUSTOM
        id: leftActionViewLoader
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: main.left
        }
        asynchronous: true
        sourceComponent: leftSideAction ? leftActionViewComponent : undefined
    }

    Component {  // CUSTOM
        id: leftActionViewComponent

        Rectangle {
            id: leftActionView
            width: root.leftActionWidth + actionThreshold
            color: UbuntuColors.red

            Icon {
                id: leftActionIcon
                anchors {
                    centerIn: parent
                    horizontalCenterOffset: actionThreshold / 2
                }
                objectName: "swipeDeleteAction"  // CUSTOM
                name: leftSideAction && _showActions ? leftSideAction.iconName : ""
                color: Theme.palette.selected.field
                height: units.gu(3)
                width: units.gu(3)
            }
        }
    }

    //Rectangle {
    Item {  // CUSTOM
       id: rightActionsView

       anchors {
           top: main.top
           left: main.right
           bottom: main.bottom
       }
       visible: _visibleRightSideActions.length > 0
       width: rightActionsRepeater.count > 0 ? rightActionsRepeater.count * (root.actionWidth + units.gu(2)) + root.actionThreshold + units.gu(2) : 0
       // color: "white"  // CUSTOM

       Rectangle {  // CUSTOM
           anchors {
               bottom: parent.bottom
               left: parent.left
               top: parent.top
           }
           color: styleMusic.common.black
           opacity: 0.7
           width: parent.width + actionThreshold
       }

       Row {
           anchors{
               top: parent.top
               left: parent.left
               leftMargin: units.gu(2)
               right: parent.right
               rightMargin: units.gu(2)
               bottom: parent.bottom
           }
           spacing: units.gu(2)
           Repeater {
               id: rightActionsRepeater

               model: _showActions ? _visibleRightSideActions : []
               Item {
                   property alias image: img

                   height: rightActionsView.height
                   width: root.actionWidth

                   Icon {
                       id: img

                       anchors.centerIn: parent
                       objectName: rightSideActions[index].objectName  // CUSTOM
                       width: units.gu(3)
                       height: units.gu(3)
                       name: modelData.iconName
                       color: root.activeAction === modelData ? UbuntuColors.blue : styleMusic.common.white  // CUSTOM
                   }
               }
           }
       }
    }

    Rectangle {
        id: main
        objectName: "mainItem"

        anchors {
            top: parent.top
            bottom: parent.bottom
        }

        width: parent.width
        color: root.selected ? root.selectedColor : root.color

        Loader {
            id: selectionIcon

            anchors {
                left: main.left
                verticalCenter: main.verticalCenter
            }
            asynchronous: true  // CUSTOM
            width: (status === Loader.Ready) ? item.implicitWidth : 0
            visible: (status === Loader.Ready) && (item.width === item.implicitWidth)

            Behavior on width {
                NumberAnimation {
                    duration: UbuntuAnimation.SnapDuration
                }
            }
        }

        Item {
            id: mainContents

            anchors {
                left: selectionIcon.right
                //leftMargin: units.gu(2)  // CUSTOM
                top: parent.top
                //topMargin: units.gu(1)  // CUSTOM
                right: parent.right
                //rightMargin: units.gu(2)  // CUSTOM
                bottom: parent.bottom
                //bottomMargin: units.gu(1)  // CUSTOM
            }
        }

        Behavior on x {
            UbuntuNumberAnimation {
                id: mainItemMoving

                easing.type: Easing.OutElastic
                duration: UbuntuAnimation.SlowDuration
            }
        }
    }

    SequentialAnimation {
        id: triggerAction

        property var currentItem: root.activeItem ? root.activeItem.image : null

        running: false
        ParallelAnimation {
            UbuntuNumberAnimation {
                target: triggerAction.currentItem
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: UbuntuAnimation.SlowDuration
                easing {type: Easing.InOutBack; }
            }
            UbuntuNumberAnimation {
                target: triggerAction.currentItem
                properties: "width, height"
                from: units.gu(3)
                to: root.actionWidth
                duration: UbuntuAnimation.SlowDuration
                easing {type: Easing.InOutBack; }
            }
        }
        PropertyAction {
            target: triggerAction.currentItem
            properties: "width, height"
            value: units.gu(3)
        }
        PropertyAction {
            target: triggerAction.currentItem
            properties: "opacity"
            value: 1.0
        }
        ScriptAction {
            script: {
                root.activeAction.triggered(root)
                mouseArea.state = ""
            }
        }
        PauseAnimation {
            duration: 500
        }
        UbuntuNumberAnimation {
            target: main
            property: "x"
            to: 0
        }
    }

    MouseArea {
        id: mouseArea

        property bool locked: root.locked || ((root.leftSideAction === null) && (root._visibleRightSideActions.count === 0))  // CUSTOM
        property bool manual: false
        property string direction: "None"
        property real lastX: -1

        anchors.fill: parent
        drag {
            target: locked ? null : main
            axis: Drag.XAxis
            minimumX: rightActionsView.visible ? -(rightActionsView.width) : 0
            maximumX: leftSideAction ? leftActionViewLoader.item.width : 0
            threshold: root.actionThreshold
        }

        states: [
            State {
                name: "LeftToRight"
                PropertyChanges {
                    target: mouseArea
                    drag.maximumX: 0
                }
            },
            State {
                name: "RightToLeft"
                PropertyChanges {
                    target: mouseArea
                    drag.minimumX: 0
                }
            }
        ]

        onMouseXChanged: {
            var offset = (lastX - mouseX)
            if (Math.abs(offset) <= root.actionThreshold) {
                return
            }
            lastX = mouseX
            direction = offset > 0 ? "RTL" : "LTR";
        }

        onPressed: {
            lastX = mouse.x
        }

        onReleased: {
            if (root.triggerActionOnMouseRelease && root.activeAction) {
                triggerAction.start()
            } else {
                root.returnToBounds()
                root.activeAction = null
            }
            lastX = -1
            direction = "None"
        }
        onClicked: {
            if (selectionMode) {  // CUSTOM - selecting a listitem should toggle selection if in selectionMode
                selected = !selected
                return
            } else if (main.x === 0) {
                root.itemClicked(mouse)
            } else if (main.x > 0) {
                var action = getActionAt(Qt.point(mouse.x, mouse.y))
                if (action && action !== -1) {
                    //action.triggered(root)
                    removeAnimation.action = action  // CUSTOM - use our animation instead
                    removeAnimation.start()  // CUSTOM
                }
            } else {
                var actionIndex = getActionAt(Qt.point(mouse.x, mouse.y))

                if (actionIndex !== -1 && actionIndex !== leftSideAction) {  // CUSTOM - can be leftAction
                    root.activeItem = rightActionsRepeater.itemAt(actionIndex)
                    root.activeAction = root.rightSideActions[actionIndex]
                    triggerAction.start()
                    return
                }
            }
            root.resetSwipe()
        }

        onPositionChanged: {
            if (mouseArea.pressed) {
                updateActiveAction()

                listItemSwiping(index)  // CUSTOM - tells other listitems to dismiss any swipe
            }
        }
        onPressAndHold: {
            if (main.x === 0) {
                root.itemPressAndHold(mouse)
            }
        }

        z: -1
    }
}
