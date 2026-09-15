import ".."
import QtQuick

Rectangle {
    id: btn

    property string glyph: ""
    signal activated

    readonly property bool navigable: true
    readonly property bool hasCursor: Cursor.item === btn

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
        onContainsMouseChanged: if (containsMouse) Cursor.item = btn
        onClicked: btn.activated()
    }
}
