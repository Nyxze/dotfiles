import ".."
import QtQuick

// Quick-settings tile. Clicking the body toggles the thing it stands for; an
// expandable tile also carries a chevron that opens its detail page instead.
Rectangle {
    id: tile

    property string glyph: ""
    property string label: ""
    property string sublabel: ""
    property bool active: false
    property bool expandable: false

    signal toggled
    signal expanded

    readonly property color foreground: active ? Theme.text : Theme.lightGray

    implicitHeight: 66
    radius: Theme.radius
    color: {
        if (active)
            return body.containsMouse ? Qt.lighter(Theme.oliveGreen, 1.15) : Theme.oliveGreen;
        return body.containsMouse ? Theme.overlay : Theme.charcoal;
    }

    Behavior on color {
        ColorAnimation {
            duration: 90
        }
    }

    MouseArea {
        id: body
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.toggled()
    }

    Text {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 12
        anchors.topMargin: 10
        text: tile.glyph
        color: tile.active ? Theme.brightYellow : Theme.mediumGray
        font.family: Theme.monoFamily
        font.pixelSize: 17
    }

    Text {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: sub.top
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        text: tile.label
        elide: Text.ElideRight
        color: tile.foreground
        font.family: Theme.fontFamily
        font.pixelSize: 13
        font.weight: Font.DemiBold
    }

    Text {
        id: sub
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.bottomMargin: 9
        text: tile.sublabel
        elide: Text.ElideRight
        color: tile.active ? Qt.alpha(Theme.text, 0.75) : Theme.mediumGray
        font.family: Theme.fontFamily
        font.pixelSize: 11
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 6
        anchors.topMargin: 6
        visible: tile.expandable
        width: 24
        height: 24
        radius: 6
        color: chevron.containsMouse ? Qt.alpha(tile.foreground, 0.2) : "transparent"

        Text {
            anchors.centerIn: parent
            text: "›"
            color: tile.foreground
            font.family: Theme.fontFamily
            font.pixelSize: 16
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
