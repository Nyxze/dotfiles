import ".."
import QtQuick

// The on/off for whatever a page is about — the radio, the adapter, the sink.
Rectangle {
    id: sw

    property bool checked: false

    signal toggled

    implicitWidth: 38
    implicitHeight: 22
    radius: height / 2
    color: checked ? Theme.oliveGreen : Theme.charcoal
    border.width: 1
    border.color: mouse.containsMouse ? Theme.brightYellow : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    Rectangle {
        x: sw.checked ? sw.width - width - 3 : 3
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        radius: 8
        color: sw.checked ? Theme.brightYellow : Theme.mediumGray

        Behavior on x {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: sw.toggled()
    }
}
