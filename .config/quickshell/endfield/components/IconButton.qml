import ".."
import QtQuick

Rectangle {
    id: btn

    property string glyph: ""

    // The stop this button belongs to. A button inside a row that is itself a
    // cursor stop is not one of its own, and hovering its icon must light the
    // row rather than steal the cursor from it.
    property var cursorTarget: btn

    signal activated

    readonly property bool navigable: cursorTarget === btn
    readonly property bool hasCursor: Cursor.item === cursorTarget

    function navActivate() {
        btn.activated();
    }

    implicitWidth: 26
    implicitHeight: 26
    radius: 6
    color: btn.hasCursor ? Theme.oliveGreen : "transparent"

    Text {
        anchors.centerIn: parent
        text: btn.glyph
        color: btn.hasCursor ? Theme.base : Theme.mediumGray
        font.family: Theme.fontFamily
        font.pixelSize: 15
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: if (containsMouse) Cursor.item = btn.cursorTarget
        onClicked: btn.activated()
    }
}
