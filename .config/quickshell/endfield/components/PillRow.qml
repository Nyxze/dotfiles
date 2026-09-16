import ".."
import QtQuick
import QtQuick.Layouts

// A segmented choice: every option on screen at once with the current one
// marked, for sets small enough that a list would be more work to read. The
// chosen segment takes the accent as a fill; the cursor answers on the border.
RowLayout {
    id: row

    // [{ key, label }]
    property var options: []
    property string current: ""

    signal picked(string key)

    spacing: Theme.space(2)
    opacity: enabled ? 1 : 0.4

    Repeater {
        model: row.options

        Rectangle {
            id: pill

            required property var modelData

            readonly property bool active: modelData.key === row.current

            readonly property bool navigable: true
            readonly property bool hasCursor: Cursor.item === pill

            function navActivate() {
                row.picked(pill.modelData.key);
            }

            Layout.fillWidth: true
            implicitHeight: Theme.space(7)
            color: pill.active ? Theme.accent : "transparent"
            border.width: pill.hasCursor ? Theme.borderEmphasis : Theme.border
            border.color: {
                if (pill.hasCursor)
                    return pill.active ? Theme.onAccent : Theme.accent;
                return Theme.line;
            }

            clip: true

            Texture {
                anchors.fill: parent
                visible: pill.active
                kind: "hatch-dark"
            }

            Text {
                anchors.centerIn: parent
                text: pill.modelData.label
                color: {
                    if (pill.active)
                        return Theme.onAccent;
                    return pill.hasCursor ? Theme.textPrimary : Theme.textSecondary;
                }
                font: Theme.label
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onContainsMouseChanged: if (containsMouse) Cursor.item = pill
                onClicked: row.picked(pill.modelData.key)
            }
        }
    }
}
