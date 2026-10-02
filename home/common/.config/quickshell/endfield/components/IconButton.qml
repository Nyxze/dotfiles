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

    implicitWidth: Theme.space(7)
    implicitHeight: Theme.space(7)
    // No selection to carry, so the cursor takes the secondary treatment: a
    // raised plate inside an accent hairline, never the fill.
    color: btn.hasCursor ? Theme.bgRaised : "transparent"
    border.width: btn.hasCursor ? Theme.border : 0
    border.color: Theme.accent

    Text {
        anchors.centerIn: parent
        text: btn.glyph
        color: btn.hasCursor ? Theme.textPrimary : Theme.textMuted
        font: Theme.glyphSmall
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
