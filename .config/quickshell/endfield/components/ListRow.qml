import ".."
import QtQuick

// One selectable entry in a detail page: a device, a session action, a paired
// headset. Selected rows keep a filled background so the current one reads at
// a glance without an extra marker.
Rectangle {
    id: item

    property string glyph: ""
    property string label: ""
    property string trailing: ""
    property bool selected: false
    property color accent: Theme.brightYellow

    signal activated

    readonly property bool hovered: mouse.containsMouse
    readonly property color foreground: hovered ? Theme.base : (selected ? accent : Theme.lightGray)

    implicitHeight: 34
    radius: 7
    color: hovered ? Theme.oliveGreen : (selected ? Theme.charcoal : "transparent")

    // Background alone reads as "selected" too weakly against charcoal tiles,
    // so the current entry also carries an accent edge.
    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        visible: item.selected && !item.hovered
        width: 3
        height: parent.height - 14
        radius: 2
        color: item.accent
    }

    Text {
        id: icon
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        visible: item.glyph !== ""
        text: item.glyph
        color: item.foreground
        font.family: Theme.monoFamily
        font.pixelSize: 14
    }

    Text {
        anchors.left: icon.visible ? icon.right : parent.left
        anchors.leftMargin: 10
        anchors.right: trail.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: item.label
        elide: Text.ElideRight
        color: item.hovered ? Theme.base : (item.selected ? Theme.text : Theme.lightGray)
        font.family: Theme.fontFamily
        font.pixelSize: 13
    }

    Text {
        id: trail
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: item.trailing
        color: item.hovered ? Theme.base : Theme.mediumGray
        font.family: Theme.fontFamily
        font.pixelSize: 11
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: item.activated()
    }
}
