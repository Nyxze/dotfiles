import ".."
import Quickshell
import QtQuick
import QtQuick.Layouts

// Label/value facts laid out two pairs per row, for connection details like
// ping, throughput or an address.
GridLayout {
    id: grid

    // [{ label: string, value: string, copy: bool }] — copy defaults falsy.
    property var entries: []

    columns: 2
    columnSpacing: Theme.space(5)
    rowSpacing: Theme.space(2)

    Repeater {
        model: grid.entries

        RowLayout {
            id: entry

            required property var modelData

            readonly property bool copyable: !!entry.modelData.copy

            Layout.fillWidth: true
            spacing: Theme.space(2)

            Text {
                text: entry.modelData.label
                color: Theme.textMuted
                font: Theme.micro
            }

            Text {
                id: value

                property bool copied: false

                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
                text: copied ? "copied" : entry.modelData.value
                color: entry.copyable && mouse.containsMouse ? Theme.accent : Theme.textPrimary
                font: Theme.bodySmall

                Timer {
                    id: resetTimer
                    interval: 1200
                    onTriggered: value.copied = false
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    enabled: entry.copyable
                    hoverEnabled: entry.copyable
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.clipboardText = entry.modelData.value;
                        value.copied = true;
                        resetTimer.restart();
                    }
                }
            }
        }
    }
}
