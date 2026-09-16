import ".."
import QtQuick

// One selectable entry in a detail page: a device, a session action, a paired
// headset. The chosen one takes the banner — hatched accent body, long
// diagonal, stepped bands — and the cursor answers on the border of a plain
// plate, inverting once it lands on the chosen row.
Item {
    id: item

    property string glyph: ""
    property string label: ""
    property string trailing: ""
    property bool selected: false
    property color accent: Theme.accent

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

    readonly property color foreground: {
        if (selected)
            return Theme.onAccent;
        return hasCursor ? Theme.textPrimary : Theme.textSecondary;
    }

    implicitHeight: 36

    BannerPlate {
        id: banner

        anchors.fill: parent
        visible: item.selected
        color: item.accent
    }

    ChamferedRect {
        anchors.fill: parent
        visible: !item.selected
        bottomRight: true
        chamfer: 4
        color: "transparent"
        borderWidth: item.hasCursor ? Theme.borderEmphasis : 0
        borderColor: Theme.accent
    }

    Text {
        id: icon
        anchors.left: parent.left
        anchors.leftMargin: Theme.space(3)
        anchors.verticalCenter: parent.verticalCenter
        visible: item.glyph !== ""
        text: item.glyph
        color: item.foreground
        font: Theme.glyphSmall
    }

    Text {
        anchors.left: icon.visible ? icon.right : parent.left
        anchors.leftMargin: Theme.space(3)
        anchors.right: trail.left
        anchors.rightMargin: Theme.space(2)
        anchors.verticalCenter: parent.verticalCenter
        text: item.label
        elide: Text.ElideRight
        color: item.foreground
        font: Theme.body
    }

    Text {
        id: trail

        anchors.right: action.visible ? action.left : parent.right
        // Clear the tail, or the readout ends up under the bands.
        anchors.rightMargin: (item.selected ? banner.clearance : 0)
            + (action.visible ? Theme.space(1) : Theme.space(3))
        anchors.verticalCenter: parent.verticalCenter
        text: item.trailing
        color: item.selected ? Qt.alpha(Theme.onAccent, 0.72) : Theme.textMuted
        font: Theme.bodySmall
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
        anchors.rightMargin: (item.selected ? banner.clearance : 0) + Theme.space(1)
        anchors.verticalCenter: parent.verticalCenter
        visible: item.actionGlyph !== "" && (item.hasCursor || actionMouse.containsMouse)
        width: Theme.space(7)
        height: Theme.space(7)
        color: actionMouse.containsMouse ? Theme.danger : "transparent"

        Text {
            anchors.centerIn: parent
            text: item.actionGlyph
            color: item.selected && !actionMouse.containsMouse ? Theme.onAccent : Theme.textPrimary
            font: Theme.glyphSmall
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
