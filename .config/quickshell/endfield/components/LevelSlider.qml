import ".."
import QtQuick

// Horizontal 0..1 slider. Reports drags through `moved` rather than writing
// `value` itself, so the owner stays the single source of truth.
Item {
    id: slider

    property real value: 0
    property bool dimmed: false
    signal moved(real value)

    implicitHeight: 18

    Rectangle {
        id: trough
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.base

        Rectangle {
            width: Math.max(0, Math.min(1, slider.value)) * parent.width
            height: parent.height
            radius: parent.radius
            color: slider.dimmed ? Theme.overlay : Theme.brightYellow
        }
    }

    Rectangle {
        x: Math.max(0, Math.min(1, slider.value)) * (parent.width - width)
        anchors.verticalCenter: parent.verticalCenter
        width: 14
        height: 14
        radius: 7
        color: mouse.pressed ? Theme.brightYellow : Theme.lightGray
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function report(x) {
            slider.moved(Math.max(0, Math.min(1, x / slider.width)));
        }

        onPressed: mouseEvent => report(mouseEvent.x)
        onPositionChanged: mouseEvent => {
            if (pressed)
                report(mouseEvent.x);
        }
    }
}
