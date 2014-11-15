/*
 * Copyright (C) 2012-2014 Canonical, Ltd.
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

import QtQuick 2.3
import Ubuntu.Components 1.1
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
    property color color: "#1e1e23"
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

    property bool reorderable: false  // CUSTOM
    property bool reordering: false  // CUSTOM
    property bool multiselectable: false  // CUSTOM

    property int previousListItemIndex: -1  // CUSTOM
    property int listItemIndex: index  // CUSTOM

    /* internal */
    property var _visibleRightSideActions: filterVisibleActions(rightSideActions)

    signal itemClicked(var mouse)
    signal itemPressAndHold(var mouse)

    signal reorder(int from, int to)  // CUSTOM

    onItemPressAndHold: {
        if (multiselectable) {
            selectionMode = true
        }
    }
    onListItemIndexChanged: {
        var i = parent.parent.selectedItems.lastIndexOf(previousListItemIndex)

        if (i !== -1) {
            parent.parent.selectedItems[i] = listItemIndex
        }

        previousListItemIndex = listItemIndex
    }

    onSelectedChanged: {
        if (selectionMode) {
            var tmp = parent.parent.selectedItems

            if (selected) {
                if (parent.parent.selectedItems.indexOf(listItemIndex) === -1) {
                    tmp.push(listItemIndex)
                    parent.parent.selectedItems = tmp
                }
            } else {
                tmp.splice(parent.parent.selectedItems.indexOf(listItemIndex), 1)
                parent.parent.selectedItems = tmp
            }
        }
    }

    onSelectionModeChanged: {  // CUSTOM
        if (reorderable && selectionMode) {
            resetSwipe()
        }

        for (var j=0; j < main.children.length; j++) {
            main.children[j].anchors.rightMargin = reorderable && selectionMode ? actionReorderLoader.width + units.gu(2) : 0
        }

        parent.parent.state = selectionMode ? "multiselectable" : "normal"

        if (!selectionMode) {
            selected = false
        }
    }

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
        var j  // CUSTOM

        if (index === _visibleRightSideActions.length) {
            newX = -(rightActionsView.width - units.gu(2))

            for (j=0; j < rightSideActions.length; j++) {  // CUSTOM
                rightActionsRepeater.itemAt(j).primed = true
            }
        } else if (index >= 1) {
            newX = -(actionFullWidth * index)

            for (j=0; j < rightSideActions.length; j++) {  // CUSTOM
                rightActionsRepeater.itemAt(j).primed = j === index
            }
        }

        updatePosition(newX)
    }

    function returnToBoundsLTR(direction)
    {
        var finalX = leftActionWidth
        if ((direction === "RTL") || (main.x <= (finalX * root.threshold)))
            finalX = 0
        updatePosition(finalX)

        if (leftSideAction !== null) {  // CUSTOM
            leftActionViewLoader.item.primed = main.x > (finalX * root.threshold)
        }
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

    function resetPrimed()  // CUSTOM
    {
        if (leftSideAction !== null) {
            leftActionViewLoader.item.primed = false
        }

        for (var j=0; j < rightSideActions.length; j++) {
            console.debug(rightActionsRepeater.itemAt(j));
            rightActionsRepeater.itemAt(j).primed = false
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

        if (pos === 0) {  // CUSTOM
            //resetPrimed()
        }
    }

    Connections {  // CUSTOM
        target: mainView
        onListItemSwiping: {
            if (i !== index) {
                root.resetSwipe();
            }
        }
    }

    Connections {  // CUSTOM
        target: root.parent.parent
        onClearSelection: selected = false
        onSelectAll: selected = true
        onStateChanged: selectionMode = root.parent.parent.state === "multiselectable"
        onVisibleChanged: {
            if (!visible) {
                reordering = false
            }
        }
    }

    Component.onCompleted: {  // CUSTOM
        if (parent.parent.selectedItems.indexOf(index) !== -1) {  // FIXME:
            selected = true
        }

        selectionMode = root.parent.parent.state === "multiselectable"
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
                source: Qt.resolvedUrl("ListItemActions/CheckBox.qml")
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

            property alias primed: leftActionIcon.primed  // CUSTOM

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

                property bool primed: false  // CUSTOM
            }
        }
    }

    //Rectangle {
    Item {  // CUSTOM
       id: rightActionsView

       anchors {
           top: main.top
           left: main.right
           leftMargin: reordering ? actionReorder.width : 0  // CUSTOM
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

                   property alias primed: img.primed  // CUSTOM

                   Icon {
                       id: img

                       anchors.centerIn: parent
                       objectName: rightSideActions[index].objectName  // CUSTOM
                       width: units.gu(3)
                       height: units.gu(3)
                       name: modelData.iconName
                       color: root.activeAction === modelData ? UbuntuColors.orange : styleMusic.common.white  // CUSTOM

                       property bool primed: false  // CUSTOM
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

    /* CUSTOM Brighten Component */
    Rectangle {
        id: listItemBrighten
        anchors {
            fill: main
        }

        color: mouseArea.pressed ? styleMusic.common.white : "transparent"
        opacity: 0.1
    }

    /* CUSTOM Reorder Component */
    Loader {
        id: actionReorderLoader
        anchors {
            bottom: parent.bottom
            right: main.right
            rightMargin: units.gu(1)
            top: parent.top
        }
        asynchronous: true
        sourceComponent: reorderable && selectionMode && root.parent.parent.selectedItems.length === 0 ? actionReorderComponent : undefined
    }

    Component {
        id: actionReorderComponent
        Item {
            id: actionReorder
            width: units.gu(4)
            visible: reorderable && selectionMode && root.parent.parent.selectedItems.length === 0

            Icon {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                }
                name: "navigation-menu"  // TODO: use proper image
                height: width
                width: units.gu(3)
            }

            MouseArea {
                id: actionReorderMouseArea
                anchors {
                    fill: parent
                }
                property int startY: 0
                property int startContentY: 0

                onPressed: {
                    root.parent.parent.interactive = false;  // stop scrolling of listview
                    startY = root.y;
                    startContentY = root.parent.parent.contentY;
                    root.z += 10;  // force ontop of other elements

                    console.debug("Reorder listitem pressed", root.y)
                }
                onMouseYChanged: root.y += mouse.y - (root.height / 2);
                onReleased: {
                    console.debug("Reorder diff by position", getDiff());

                    var diff = getDiff();

                    // Remove the height of the actual item if moved down
                    if (diff > 0) {
                        diff -= 1;
                    }

                    root.parent.parent.interactive = true;  // reenable scrolling

                    if (diff === 0) {
                        // Nothing has changed so reset the item
                        // z index is restored after animation
                        resetListItemYAnimation.start();
                    }
                    else {
                        var newIndex = index + diff;

                        if (newIndex < 0) {
                            newIndex = 0;
                        }
                        else if (newIndex > root.parent.parent.count - 1) {
                            newIndex = root.parent.parent.count - 1;
                        }

                        root.z -= 10;  // restore z index
                        reorder(index, newIndex)
                    }
                }

                function getDiff() {
                    // Get the amount of items that have been passed over (by centre)
                    return Math.round((((root.y - startY) + (root.parent.parent.contentY - startContentY)) / root.height) + 0.5);
                }
            }

            SequentialAnimation {
                id: resetListItemYAnimation
                UbuntuNumberAnimation {
                    target: root;
                    property: "y";
                    to: actionReorderMouseArea.startY
                }
                ScriptAction {
                    script: {
                        root.z -= 10;  // restore z index
                    }
                }
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

        property bool locked: root.locked || ((root.leftSideAction === null) && (root._visibleRightSideActions.count === 0)) || reordering  // CUSTOM
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
            if (selectionMode) {  // CUSTOM
                selected = !selected
                return
            }
            else if (main.x === 0) {
                root.itemClicked(mouse)
            } else if (main.x > 0) {
                var action = getActionAt(Qt.point(mouse.x, mouse.y))
                if (action && action !== -1) {
                    //action.triggered(root)
                    removeAnimation.action = action  // CUSTOM
                    removeAnimation.start()  // CUSTOM
                }
            } else {
                var actionIndex = getActionAt(Qt.point(mouse.x, mouse.y))
                if (actionIndex !== -1) {
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

                listItemSwiping(index)  // CUSTOM
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
