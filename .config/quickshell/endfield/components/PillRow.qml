import ".."
import QtQuick
import QtQuick.Layouts

// A segmented choice: every option on screen at once with the current one
// filled, for sets small enough that a list would be more work to read.
RowLayout {
    id: row

    // [{ key, label }]
    property var options: []
    property string current: ""

    signal picked(string key)

    spacing: 6
    opacity: enabled ? 1 : 0.4

    Repeater {
        model: row.options

        Rectangle {
            id: pill

            required property var modelData

            readonly property bool active: modelData.key === row.current

            Layout.fillWidth: true
            implicitHeight: 26
            radius: 7
            color: active ? Theme.charcoal : (mouse.containsMouse ? Theme.oliveGreen : "transparent")
            border.width: active ? 0 : 1
            border.color: Theme.charcoal

            Text {
                anchors.centerIn: parent
                text: pill.modelData.label
                color: pill.active ? Theme.brightYellow : (mouse.containsMouse ? Theme.base : Theme.lightGray)
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: pill.active ? Font.DemiBold : Font.Normal
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: row.picked(pill.modelData.key)
            }
        }
    }
}
