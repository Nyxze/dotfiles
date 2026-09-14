import ".."
import "../components"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page

    // uwsm owns the session, so logging out means stopping it rather than
    // asking Hyprland to exit under it.
    readonly property var actions: [
        {
            glyph: "󰌾",
            label: "Lock",
            command: ["hyprlock"]
        },
        {
            glyph: "󰒲",
            label: "Suspend",
            command: ["systemctl", "suspend"]
        },
        {
            glyph: "󰗽",
            label: "Log out",
            command: ["uwsm", "stop"]
        },
        {
            glyph: "󰜉",
            label: "Restart",
            command: ["systemctl", "reboot"]
        },
        {
            glyph: "󰐥",
            label: "Shut down",
            command: ["systemctl", "poweroff"]
        }
    ]

    readonly property var tlpModes: [
        {
            mode: "auto",
            label: "Automatic"
        },
        {
            mode: "ac",
            label: "Performance"
        },
        {
            mode: "bat",
            label: "Battery saver"
        }
    ]

    spacing: 16

    Process {
        id: runner
    }

    Section {
        Layout.fillWidth: true
        title: "Power mode"

        Repeater {
            model: page.tlpModes

            ListRow {
                required property var modelData

                Layout.fillWidth: true
                label: modelData.label
                selected: TlpService.matches(modelData.mode)
                onActivated: TlpService.setMode(modelData.mode)
            }
        }
    }

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
                onActivated: {
                    runner.command = modelData.command;
                    runner.running = true;
                }
            }
        }
    }
}
