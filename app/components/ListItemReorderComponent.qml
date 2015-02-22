import QtQuick 2.3
import Ubuntu.Components 1.1
import "../"


Item {
    id: actionReorder
    width: units.gu(4)

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
