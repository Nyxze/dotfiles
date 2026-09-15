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

    // Optional destructive shortcut on the right — forget a network, unpair a
    // device. Empty means the row has no second action.
    property string actionGlyph: ""

    signal activated
    signal actionActivated

    readonly property bool navigable: true
    readonly property bool hasCursor: Cursor.item === item

    function navActivate() {
        item.activated();
    }

    function navRemove() {
        if (item.actionGlyph !== "")
            item.actionActivated();
    }

    readonly property bool hovered: hasCursor
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
        anchors.right: action.visible ? action.left : parent.right
        anchors.rightMargin: action.visible ? 4 : 10
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
        onContainsMouseChanged: if (containsMouse) Cursor.item = item
        onClicked: item.activated()
    }

    // Stacked after the row's own MouseArea so it wins the click.
    Rectangle {
        id: action

        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        visible: item.actionGlyph !== "" && (item.hovered || actionMouse.containsMouse)
        width: 26
        height: 26
        radius: 6
        color: actionMouse.containsMouse ? Theme.critical : "transparent"

        Text {
            anchors.centerIn: parent
            text: item.actionGlyph
            color: actionMouse.containsMouse ? Theme.text : Theme.base
            font.family: Theme.fontFamily
            font.pixelSize: 14
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: item.actionActivated()
        }
    }
}
