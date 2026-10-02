import ".."
import "../components"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: Theme.space(4)

    // Scanning drains the battery, so it only runs while this page is shown.
    Component.onCompleted: BluetoothService.setDiscovering(true)
    Component.onDestruction: BluetoothService.setDiscovering(false)

    PageHeader {
        Layout.fillWidth: true
        glyph: BluetoothService.enabled ? "󰂯" : "󰂲"
        title: {
            if (!BluetoothService.adapter)
                return "No adapter";
            if (!BluetoothService.enabled)
                return "Bluetooth off";
            return BluetoothService.adapter.name;
        }
        subtitle: {
            if (BluetoothService.discovering)
                return "SCANNING…";
            const n = BluetoothService.connected.length;
            return n > 0 ? n + " CONNECTED" : "";
        }
        dimmed: !BluetoothService.enabled

        IconButton {
            glyph: "󰑐"
            enabled: BluetoothService.enabled
            opacity: enabled ? 1 : 0.4
            onActivated: {
                BluetoothService.setDiscovering(false);
                BluetoothService.setDiscovering(true);
            }
        }

        ToggleSwitch {
            checked: BluetoothService.enabled
            onToggled: BluetoothService.toggleAdapter()
        }
    }

    Section {
        Layout.fillWidth: true
        title: "Connected"
        visible: BluetoothService.connected.length > 0

        Repeater {
            model: BluetoothService.connected

            ListRow {
                required property var modelData

                Layout.fillWidth: true
                glyph: BluetoothService.glyph(modelData)
                label: BluetoothService.label(modelData)
                trailing: BluetoothService.statusOf(modelData)
                selected: modelData.connected
                actionGlyph: "󰅖"
                onActionActivated: BluetoothService.forget(modelData)
                onActivated: BluetoothService.activate(modelData)
            }
        }
    }

    Section {
        Layout.fillWidth: true
        title: "Paired"
        visible: BluetoothService.paired.length > 0

        Repeater {
            model: BluetoothService.paired

            ListRow {
                required property var modelData

                Layout.fillWidth: true
                glyph: BluetoothService.glyph(modelData)
                label: BluetoothService.label(modelData)
                trailing: BluetoothService.statusOf(modelData)
                selected: modelData.connected
                actionGlyph: "󰅖"
                onActionActivated: BluetoothService.forget(modelData)
                onActivated: BluetoothService.activate(modelData)
            }
        }
    }

    Section {
        Layout.fillWidth: true
        title: "Available"
        visible: BluetoothService.discovered.length > 0

        Repeater {
            model: BluetoothService.discovered

            ListRow {
                required property var modelData

                Layout.fillWidth: true
                glyph: BluetoothService.glyph(modelData)
                label: BluetoothService.label(modelData)
                trailing: BluetoothService.statusOf(modelData)
                selected: modelData.connected
                onActivated: BluetoothService.activate(modelData)
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: BluetoothService.enabled && BluetoothService.connected.length === 0
            && BluetoothService.paired.length === 0 && BluetoothService.discovered.length === 0
        text: "No device"
        color: Theme.line
        font: Theme.body
    }
}
