import ".."
import QtQuick

// The on/off for whatever a page is about — the radio, the adapter, the sink.
//
// The one rounded thing in the language, and deliberately so: the concept
// boards bevel every plate and keep the switch a pill, because the travel of a
// knob along a track is what reads as a switch at all. A bevelled switch reads
// as a very small button.
Rectangle {
    id: sw

    property bool checked: false

    signal toggled

    readonly property bool navigable: true
    readonly property bool hasCursor: Cursor.item === sw

    function navActivate() {
        sw.toggled();
    }

    implicitWidth: Theme.space(10)
    implicitHeight: Theme.space(5)
    radius: height / 2
    color: checked ? Theme.accent : Theme.bgRaised
    border.width: sw.hasCursor ? Theme.borderEmphasis : Theme.border
    border.color: sw.hasCursor ? Theme.accent : Theme.line

    Behavior on color {
        ColorAnimation {
            duration: Theme.durHover
        }
    }

    // Off, the knob is a ring on the dark track; on, it is solid against the
    // accent. The shape carries the state as well as the position does.
    Rectangle {
        id: knob

        x: sw.checked ? sw.width - width - 2 : 2
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.space(4)
        height: Theme.space(4)
        radius: height / 2
        color: sw.checked ? Theme.onAccent : Theme.bgDeep
        border.width: sw.checked ? 0 : 2
        border.color: Theme.accent

        Behavior on x {
            NumberAnimation {
                duration: Theme.durHover
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: if (containsMouse) Cursor.item = sw
        onClicked: sw.toggled()
    }
}
