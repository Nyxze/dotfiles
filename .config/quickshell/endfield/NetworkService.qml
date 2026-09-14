pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick

// Single view onto NetworkManager. The device list is empty for about a second
// after startup, so everything here has to tolerate a null device.
Singleton {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi) || null
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired) || null

    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool online: Networking.connectivity === NetworkConnectivity.Full

    // Connected first, then saved, then by signal strength, so the list stays
    // still while a scan keeps rewriting it.
    readonly property var networks: {
        if (!wifi)
            return [];
        const all = wifi.networks.values.slice();
        all.sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            if (a.known !== b.known)
                return a.known ? -1 : 1;
            return b.signalStrength - a.signalStrength;
        });
        return all;
    }

    readonly property var active: networks.find(n => n.connected) || null
    readonly property bool wiredUp: wired !== null && wired.connected

    readonly property string glyph: {
        if (wiredUp)
            return "󰈀";
        if (!wifiEnabled)
            return "󰤭";
        return active ? signalGlyph(active.signalStrength) : "󰤯";
    }

    // NetworkDevice.address is the MAC; the IPv4 has to come from iproute2.
    property string ipv4: ""

    readonly property string interfaceName: {
        if (wiredUp)
            return wired.name;
        return active && wifi ? wifi.name : "";
    }

    readonly property string status: {
        if (wiredUp)
            return wired.name;
        if (!wifi)
            return "No device";
        if (!wifiEnabled)
            return "Wi-Fi off";
        if (!active)
            return "Not connected";
        return online ? active.name : active.name + " · no internet";
    }

    // signalStrength is a 0..1 fraction, not the 0..100 NetworkManager reports.
    function signalGlyph(strength) {
        if (strength >= 0.75)
            return "󰤨";
        if (strength >= 0.5)
            return "󰤥";
        if (strength >= 0.25)
            return "󰤢";
        return "󰤟";
    }

    function secured(network) {
        return network.security !== WifiSecurityType.Open
            && network.security !== WifiSecurityType.Unknown;
    }

    function securityLabel(network) {
        return secured(network) ? WifiSecurityType.toString(network.security) : "open";
    }

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    // Scanning is only worth its battery while someone is looking at the list.
    function setScanning(on) {
        if (wifi)
            wifi.scannerEnabled = on;
    }

    onInterfaceNameChanged: addressQuery.running = true

    Process {
        id: addressQuery
        command: ["ip", "-j", "-4", "addr", "show"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                if (root.interfaceName === "") {
                    root.ipv4 = "";
                    return;
                }
                try {
                    const link = JSON.parse(this.text).find(e => e.ifname === root.interfaceName);
                    const info = link && link.addr_info.length ? link.addr_info[0] : null;
                    root.ipv4 = info ? info.local : "";
                } catch (error) {
                    root.ipv4 = "";
                }
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: addressQuery.running = true
    }
}
