import ".."
import QtQuick

// One entry of a vertical navigation column: a glyph, a title and a line of
// context. The selected entry takes the accent as a banner — solid body, long
// diagonal trailing edge, two stepped bands behind it — with a dark badge
// around its glyph, and puts a rail at the column's own left edge, detached
// from the plate and standing past it top and bottom, so the column reads as
// marked rather than the row as merely filled.
//
// Selection and focus stay on separate channels: selected takes the banner,
// the cursor answers on the border of a plain plate.
Item {
    id: row

    property string glyph: ""
    property string title: ""
    property string subtitle: ""
    property bool selected: false

    signal activated

    readonly property bool navigable: true
    readonly property bool hasCursor: Cursor.item === row

    function navActivate() {
        row.activated();
    }

    readonly property color foreground: selected ? Theme.onAccent : Theme.textPrimary

    implicitHeight: Theme.space(12)

    // Stands past the plate at both ends; that overhang is what stops it
    // reading as the plate's own border.
    Rectangle {
        x: 0
        y: -Theme.space(2)
        width: Theme.space(1)
        height: row.height + Theme.space(4)
        visible: row.selected
        color: Theme.accent
    }

    // The area both plates fill and the content is laid out against, so the
    // two never drift apart.
    Item {
        id: field

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: Theme.space(6)

        BannerPlate {
            id: banner
            anchors.fill: parent
            visible: row.selected
            color: Theme.accent
        }

        ChamferedRect {
            anchors.fill: parent
            visible: !row.selected
            bottomRight: true
            chamfer: Theme.space(2)
            color: row.hasCursor ? Theme.bgRaised : "transparent"
            borderWidth: row.hasCursor ? Theme.border : 0
            borderColor: Theme.accent

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durHover
                }
            }
        }
    }

    // The badge is the selected state's own device: off the accent it would be
    // a dark square on a dark ground, which says nothing.
    Rectangle {
        id: badge

        anchors.left: field.left
        anchors.leftMargin: Theme.space(3)
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.space(7)
        height: Theme.space(7)
        visible: row.selected
        color: Theme.onAccent
    }

    Text {
        anchors.centerIn: badge
        text: row.glyph
        color: row.selected ? Theme.accent : Theme.textMuted
        font: Theme.glyphMedium
    }

    Column {
        anchors.left: badge.right
        anchors.leftMargin: Theme.space(3)
        anchors.right: field.right
        // Clear the tail, or the subtitle runs out under the bands.
        anchors.rightMargin: (row.selected ? banner.clearance : 0) + Theme.space(3)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.space(1)

        Text {
            width: parent.width
            text: row.title
            elide: Text.ElideRight
            color: row.foreground
            font: Theme.h3
        }

        Text {
            width: parent.width
            visible: row.subtitle !== ""
            text: row.subtitle
            elide: Text.ElideRight
            color: row.selected ? Qt.alpha(Theme.onAccent, 0.72) : Theme.textMuted
            font: Theme.bodySmall
        }
    }

    MouseArea {
        anchors.fill: field
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: if (containsMouse) Cursor.item = row
        onClicked: row.activated()
    }
}
