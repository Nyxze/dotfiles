import ".."
import "../components"
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

GridLayout {
    id: tiles

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var connectedDevice: Bluetooth.devices.values.find(d => d.connected) || null

    signal pageRequested(string page)

    columns: 2
    columnSpacing: 10
    rowSpacing: 10

    Tile {
        Layout.fillWidth: true

        glyph: NetworkService.glyph
        label: "Network"
        sublabel: NetworkService.status
        active: NetworkService.online
        expandable: true

        onToggled: NetworkService.toggleWifi()
        onExpanded: tiles.pageRequested("network")
    }

    Tile {
        Layout.fillWidth: true

        glyph: tiles.adapter && tiles.adapter.enabled ? "󰂯" : "󰂲"
        label: "Bluetooth"
        sublabel: {
            if (!tiles.adapter)
                return "No adapter";
            if (!tiles.adapter.enabled)
                return "Off";
            if (tiles.adapter.discovering)
                return "Scanning…";
            return tiles.connectedDevice
                ? (tiles.connectedDevice.deviceName || tiles.connectedDevice.name)
                : "Not connected";
        }
        active: tiles.adapter ? tiles.adapter.enabled : false
        expandable: true

        onToggled: {
            if (tiles.adapter)
                tiles.adapter.enabled = !tiles.adapter.enabled;
        }
        onExpanded: tiles.pageRequested("bluetooth")
    }

    Tile {
        Layout.fillWidth: true

        glyph: NotificationService.doNotDisturb ? "󰂛" : "󰂚"
        label: "Do not disturb"
        sublabel: {
            if (NotificationService.doNotDisturb)
                return "Toasts muted";
            const count = NotificationService.history.values.length;
            return count === 0 ? "Nothing waiting" : count + " waiting";
        }
        active: NotificationService.doNotDisturb

        onToggled: NotificationService.doNotDisturb = !NotificationService.doNotDisturb
    }

    Tile {
        Layout.fillWidth: true

        glyph: "󰓅"
        label: "TLP"
        sublabel: TlpService.mode
        active: !TlpService.onBattery

        onToggled: TlpService.toggle()
    }
}
