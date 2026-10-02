import ".."
import "../components"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: Theme.space(4)

    PageHeader {
        Layout.fillWidth: true
        glyph: "󰂯"
        title: "Bluetooth"
        subtitle: "Managed by Blueman"
    }

    Section {
        Layout.fillWidth: true
        title: "Devices"

        Text {
            Layout.fillWidth: true
            text: "Use Blueman to pair and manage Bluetooth devices."
            color: Theme.textSecondary
            font: Theme.body
            wrapMode: Text.WordWrap
        }
    }
}
