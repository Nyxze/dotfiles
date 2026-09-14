import ".."
import "../components"
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

Card {
    id: power

    readonly property var battery: UPower.displayDevice
    readonly property bool charging: battery
        && (battery.state === UPowerDeviceState.Charging
            || battery.state === UPowerDeviceState.FullyCharged)

    // TLP, not power-profiles-daemon, so UPower.PowerProfiles reports nothing
    // on this machine. tlp-stat reads the mode without root.
    property string tlpMode: "…"

    function humanise(seconds) {
        if (!seconds || seconds <= 0)
            return "";
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.round((seconds % 3600) / 60);
        return hours > 0 ? `${hours} h ${minutes} min` : `${minutes} min`;
    }

    title: "Power"

    Process {
        id: tlpQuery
        command: ["tlp-stat", "-m"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: power.tlpMode = this.text.trim() || "unknown"
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: tlpQuery.running = true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Text {
            text: power.charging ? "󰂄" : "󰁹"
            color: power.charging ? Theme.success : Theme.lightGray
            font.family: Theme.monoFamily
            font.pixelSize: 26
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: power.battery ? Math.round(power.battery.percentage * 100) + "%" : "--"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 20
                font.weight: Font.DemiBold
            }

            Text {
                readonly property string remaining: power.battery
                    ? power.humanise(power.charging ? power.battery.timeToFull : power.battery.timeToEmpty)
                    : ""

                visible: text !== ""
                text: remaining === ""
                    ? (power.charging ? "On AC" : "")
                    : (power.charging ? remaining + " to full" : remaining + " left")
                color: Theme.mediumGray
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 4
        radius: 2
        color: Theme.base

        Rectangle {
            width: parent.width * (power.battery ? power.battery.percentage : 0)
            height: parent.height
            radius: parent.radius
            color: {
                if (power.charging)
                    return Theme.success;
                if (!power.battery || power.battery.percentage > 0.3)
                    return Theme.brightYellow;
                return power.battery.percentage > 0.15 ? Theme.feintYellow : Theme.critical;
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: "TLP  " + power.tlpMode
            color: Theme.mediumGray
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        // Switching modes goes through pkexec and will ask for a password.
        IconButton {
            glyph: "󰑐"
            onActivated: tlpToggle.running = true
        }
    }

    Process {
        id: tlpToggle
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/tlp-ctl.sh", "toggle"]
        onExited: tlpQuery.running = true
    }
}
