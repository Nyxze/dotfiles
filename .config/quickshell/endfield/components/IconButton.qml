import ".."
import QtQuick

Rectangle {
    id: btn

    property string glyph: ""
    signal activated

    implicitWidth: 26
    implicitHeight: 26
    radius: 6
    color: mouse.containsMouse ? Theme.oliveGreen : "transparent"

    Text {
        anchors.centerIn: parent
        text: btn.glyph
        color: mouse.containsMouse ? Theme.base : Theme.mediumGray
        font.family: Theme.fontFamily
        font.pixelSize: 15
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.activated()
    }
}
