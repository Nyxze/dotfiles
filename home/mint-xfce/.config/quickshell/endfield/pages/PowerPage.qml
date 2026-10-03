import ".."
import "../components"
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page

    readonly property var actions: [
        { glyph: "󰌾", label: "Lock", command: ["xflock4"] },
        { glyph: "󰒲", label: "Suspend", command: ["systemctl", "suspend"] },
        { glyph: "󰗽", label: "Log out", command: ["i3-msg", "exit"] },
        { glyph: "󰜉", label: "Restart", command: ["systemctl", "reboot"] },
        { glyph: "󰐥", label: "Shut down", command: ["systemctl", "poweroff"] }
    ]

    spacing: Theme.space(4)
    Process { id: runner }

    Section {
        Layout.fillWidth: true
        title: "Session"
        Repeater {
            model: page.actions
            ListRow {
                required property var modelData
                Layout.fillWidth: true
                glyph: modelData.glyph
                label: modelData.label
                onActivated: { runner.command = modelData.command; runner.running = true; }
            }
        }
    }
}
