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
    columnSpacing: 18
    rowSpacing: 6

    Repeater {
        model: grid.entries

        RowLayout {
            id: entry

            required property var modelData

            readonly property bool copyable: !!entry.modelData.copy

            Layout.fillWidth: true
            spacing: 8

            Text {
                text: entry.modelData.label
                color: Theme.mediumGray
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 0.6
            }

            Text {
                id: value

                property bool copied: false

                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
                text: copied ? "copied" : entry.modelData.value
                color: entry.copyable && mouse.containsMouse ? Theme.brightYellow : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold

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
                        Quickshell.execDetached(["wl-copy", entry.modelData.value]);
                        value.copied = true;
                        resetTimer.restart();
                    }
                }
            }
        }
    }
}
