import ".."
import "../components"
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: Theme.space(4)

    Process { id: settings; command: ["xfce4-display-settings"] }

    PageHeader {
        Layout.fillWidth: true
        glyph: "󰍺"
        title: "Displays"
        subtitle: "Xfce remains the display authority"
    }

    Section {
        Layout.fillWidth: true
        title: "Configuration"

        ListRow {
            Layout.fillWidth: true
            glyph: "󰍺"
            label: "Advanced settings"
            trailing: "XFCE"
            onActivated: settings.running = true
        }
    }
}
