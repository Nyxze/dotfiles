import ".."
import QtQuick

// A section header the way the source draws one: a small accent badge, the
// label, then a long thin rule running out to the right edge.
Item {
    id: root

    property string text: ""

    implicitHeight: Theme.space(4)

    Rectangle {
        id: badge

        anchors.verticalCenter: parent.verticalCenter
        width: Theme.space(1)
        height: Theme.space(3)
        color: Theme.accent
    }

    Text {
        id: caption

        anchors.left: badge.right
        anchors.leftMargin: Theme.space(2)
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        color: Theme.textSecondary
        font: Theme.label
    }

    Rectangle {
        anchors.left: caption.right
        anchors.leftMargin: Theme.space(3)
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.border
        color: Theme.line
    }
}
