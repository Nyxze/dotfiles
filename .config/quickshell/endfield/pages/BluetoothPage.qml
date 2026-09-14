import ".."
import "../components"
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page

    readonly property var adapter: Bluetooth.defaultAdapter

    // Connected first, then paired, so the list does not reshuffle every time a
    // scan turns up something new.
    readonly property var devices: {
        const all = Bluetooth.devices.values.slice();
        all.sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            if (a.paired !== b.paired)
                return a.paired ? -1 : 1;
            return (a.deviceName || a.name || "").localeCompare(b.deviceName || b.name || "");
        });
        return all;
    }

    function stateOf(device) {
        if (device.state === BluetoothDeviceState.Connecting)
            return "connecting…";
        if (device.state === BluetoothDeviceState.Disconnecting)
            return "disconnecting…";
        if (device.connected)
            return device.batteryAvailable ? Math.round(device.battery * 100) + "%" : "connected";
        return device.paired ? "paired" : "";
    }

    spacing: 16

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: {
                if (!page.adapter)
                    return "No adapter";
                if (!page.adapter.enabled)
                    return "Adapter off";
                return page.adapter.discovering ? "Scanning…" : page.adapter.name;
            }
            elide: Text.ElideRight
            color: Theme.lightGray
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }

        IconButton {
            enabled: page.adapter && page.adapter.enabled
            opacity: enabled ? 1 : 0.4
            glyph: "󰑐"
            onActivated: {
                if (page.adapter)
                    page.adapter.discovering = !page.adapter.discovering;
            }
        }

        IconButton {
            glyph: page.adapter && page.adapter.enabled ? "󰂯" : "󰂲"
            onActivated: {
                if (page.adapter)
                    page.adapter.enabled = !page.adapter.enabled;
            }
        }
    }

    Section {
        Layout.fillWidth: true
        visible: page.adapter && page.adapter.enabled
        title: "Devices"

        Text {
            Layout.fillWidth: true
            visible: page.devices.length === 0
            text: "No device"
            color: Theme.overlay
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        Repeater {
            model: page.devices

            ListRow {
                required property var modelData

                readonly property bool busy: modelData.state === BluetoothDeviceState.Connecting
                    || modelData.state === BluetoothDeviceState.Disconnecting

                Layout.fillWidth: true
                glyph: modelData.connected ? "󰂱" : "󰂯"
                label: modelData.deviceName || modelData.name || modelData.address
                trailing: page.stateOf(modelData)
                selected: modelData.connected
                actionGlyph: modelData.paired ? "󰅖" : ""

                onActionActivated: modelData.forget()
                onActivated: {
                    if (busy)
                        return;
                    if (modelData.connected)
                        modelData.disconnect();
                    else if (modelData.paired)
                        modelData.connect();
                    else
                        modelData.pair();
                }
            }
        }
    }
}
