import ".."
import QtQuick
import QtQuick.Layouts

// A named level with a slider underneath — volume, mic gain, brightness share
// this shape even though none of those words belong in this file.
ColumnLayout {
    id: row

    property string glyph: ""
    property string label: ""
    property real value: 0
    property real maximum: 1
    property bool dimmed: false

    signal glyphActivated
    signal moved(real value)

    readonly property bool navigable: true
    readonly property bool hasCursor: Cursor.item === row

    function navActivate() {
        row.glyphActivated();
    }

    function navAdjust(step) {
        row.moved(Math.max(0, Math.min(row.maximum, row.value + step * 0.05 * row.maximum)));
    }

    spacing: 2

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        // Wrapped in an Item: a MouseArea placed straight into a Layout is
        // sized by it instead of covering the glyph.
        Item {
            id: glyphArea

            Layout.preferredWidth: 20
            implicitHeight: glyphText.implicitHeight

            Text {
                id: glyphText
                anchors.centerIn: parent
                text: row.glyph
                color: row.dimmed ? Theme.overlay : (row.hasCursor ? Theme.brightYellow : Theme.lightGray)
                font.family: Theme.monoFamily
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
            }

            MouseArea {
                id: glyphMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onContainsMouseChanged: if (containsMouse) Cursor.item = row
                onClicked: row.glyphActivated()
            }
        }

        Text {
            Layout.fillWidth: true
            text: row.label
            elide: Text.ElideRight
            color: Theme.lightGray
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        Text {
            Layout.minimumWidth: 36
            horizontalAlignment: Text.AlignRight
            text: Math.round(row.value * 100) + "%"
            color: Theme.mediumGray
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
    }

    LevelSlider {
        Layout.fillWidth: true
        Layout.leftMargin: 28
        value: row.value / row.maximum
        dimmed: row.dimmed
        onMoved: level => row.moved(level * row.maximum)
    }
}
