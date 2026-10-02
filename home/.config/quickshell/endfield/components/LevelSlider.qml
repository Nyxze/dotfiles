import ".."
import QtQuick

// Horizontal 0..1 slider. Reports drags through `moved` rather than writing
// `value` itself, so the owner stays the single source of truth.
Item {
    id: slider

    property real value: 0
    property bool dimmed: false
    signal moved(real value)

    implicitHeight: Theme.space(5)

    // The trough is a well, cut into the panel rather than laid on it.
    Rectangle {
        id: trough
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: Theme.space(1)
        color: Theme.bgDeep

        Rectangle {
            width: Math.max(0, Math.min(1, slider.value)) * parent.width
            height: parent.height
            color: slider.dimmed ? Theme.line : Theme.accent
        }
    }

    Rectangle {
        x: Math.max(0, Math.min(1, slider.value)) * (parent.width - width)
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.space(3)
        height: Theme.space(3)
        color: mouse.pressed ? Theme.accent : Theme.textSecondary
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
