import ".."
import QtQuick

// Quick-settings tile. Clicking the body toggles the thing it stands for; an
// expandable tile also carries a chevron that opens its detail page instead.
//
// A tile is a toggle, not a choice among several, so its on state takes the
// accent rail rather than the fill — four tiles all filled would be most of a
// panel gone yellow. The cursor answers on the border.
ChamferedRect {
    id: tile

    property string glyph: ""
    property string label: ""
    property string sublabel: ""
    property bool active: false
    property bool expandable: false

    signal toggled
    signal expanded

    readonly property bool navigable: true
    readonly property bool hasCursor: Cursor.item === tile

    function navActivate() {
        tile.toggled();
    }

    readonly property color foreground: active ? Theme.textPrimary : Theme.textSecondary

    implicitHeight: 64
    // Opposite corners cut, not all four: a plate reads as machined rather than
    // as an octagon.
    topLeft: true
    bottomRight: true
    color: Theme.bgRaised
    borderColor: hasCursor ? Theme.accent : Theme.line
    borderWidth: hasCursor ? Theme.borderEmphasis : Theme.border

    Behavior on color {
        ColorAnimation {
            duration: Theme.durHover
        }
    }

    // The standing state, at the width the dock marks its active item with.
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.chamfer
        visible: tile.active
        width: Theme.space(1)
        color: Theme.accent
    }

    MouseArea {
        id: body
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: if (containsMouse) Cursor.item = tile
        onClicked: tile.toggled()
    }

    Text {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: Theme.space(3)
        anchors.topMargin: Theme.space(2)
        text: tile.glyph
        color: tile.active ? Theme.accent : Theme.textMuted
        font: Theme.glyphMedium
    }

    Text {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: sub.top
        anchors.leftMargin: Theme.space(3)
        anchors.rightMargin: Theme.space(3)
        text: tile.label
        elide: Text.ElideRight
        color: tile.foreground
        font: Theme.label
    }

    Text {
        id: sub
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Theme.space(3)
        anchors.rightMargin: Theme.space(3)
        anchors.bottomMargin: Theme.space(2)
        text: tile.sublabel
        elide: Text.ElideRight
        color: Theme.textMuted
        font: Theme.bodySmall
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: Theme.space(1)
        anchors.topMargin: Theme.space(1)
        visible: tile.expandable
        width: Theme.space(6)
        height: Theme.space(6)
        color: chevron.containsMouse ? Qt.alpha(tile.foreground, 0.2) : "transparent"

        Text {
            anchors.centerIn: parent
            text: "›"
            color: tile.foreground
            font: Theme.h2
        }

        MouseArea {
            id: chevron
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.expanded()
        }
    }
}
