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

    // NetworkManager already tells a captive portal apart from a dead link, so
    // "sign-in required" costs no probe of our own.
    readonly property string reach: {
        if (!wiredUp && !active)
            return "";
        switch (Networking.connectivity) {
        case NetworkConnectivity.Full:
            return "connected";
        case NetworkConnectivity.Portal:
            return "sign-in required";
        case NetworkConnectivity.Limited:
            return "limited access";
        case NetworkConnectivity.None:
            return "no internet";
        default:
            return "";
        }
    }

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
    property string gateway: ""
    property real rxRate: -1
    property real txRate: -1
    property real rxTotal: -1
    property real txTotal: -1
    property var lastSample: null
    property real latency: -1
    property real packetLoss: -1
    property string dns: "dhcp"
    property string band: ""
    property string bandSelected: "auto"
    property var bandAvailable: []
    property bool busy: false
    property bool polling: false

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

    readonly property string linkDetail: {
        if (wiredUp)
            return wired.linkSpeed + " Mb/s";
        return (active && band) ? band + " GHz" : "";
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

    // Gates every probe below; the bar's own 30s IPv4 timer ignores this.
    function setPolling(on) {
        root.polling = on;
    }

    function setDns(provider) {
        if (root.busy)
            return;
        root.busy = true;
        controlProcess.command = [root.netCtlScript, "dns", provider];
        controlProcess.running = true;
    }

    function setBand(value) {
        if (root.busy)
            return;
        root.busy = true;
        controlProcess.command = [root.netCtlScript, "band", value];
        controlProcess.running = true;
    }

    function formatBytes(bytes) {
        if (bytes < 0)
            return "—";
        if (bytes < 1024)
            return bytes.toFixed(0) + " B";
        const units = ["kB", "MB", "GB", "TB"];
        let value = bytes / 1024, unit = 0;
        while (value >= 1024 && unit < units.length - 1) {
            value /= 1024;
            unit++;
        }
        return value.toFixed(1) + " " + units[unit];
    }

    function formatRate(bytesPerSecond) {
        return bytesPerSecond < 0 ? "—" : formatBytes(bytesPerSecond) + "/s";
    }

    function formatLatency(ms) {
        return ms < 0 ? "—" : Math.round(ms) + " ms";
    }

    function formatLoss(percent) {
        return percent < 0 ? "—" : Math.round(percent) + "%";
    }

    // Totals belong to an interface, not to the machine.
    onInterfaceNameChanged: {
        addressQuery.running = true;
        root.rxRate = -1;
        root.txRate = -1;
        root.rxTotal = -1;
        root.txTotal = -1;
        root.lastSample = null;
    }

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

    Process {
        id: gatewayQuery
        command: ["ip", "-j", "route", "show", "default"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const routes = JSON.parse(this.text);
                    const match = routes.find(r => r.dev === root.interfaceName) || routes.find(r => r.gateway);
                    root.gateway = match ? (match.gateway || "") : "";
                } catch (error) {
                    root.gateway = "";
                }
            }
        }
    }

    // $IF goes through the environment, not string interpolation into the shell.
    Process {
        id: throughputQuery
        environment: ({ IF: root.interfaceName })
        command: ["sh", "-c", "cat /sys/class/net/$IF/statistics/rx_bytes /sys/class/net/$IF/statistics/tx_bytes"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                if (lines.length < 2)
                    return;
                const rx = Number(lines[0]);
                const tx = Number(lines[1]);
                const now = Date.now();
                if (root.lastSample) {
                    const dt = (now - root.lastSample.time) / 1000;
                    root.rxRate = (rx - root.lastSample.rx) / dt;
                    root.txRate = (tx - root.lastSample.tx) / dt;
                }
                root.rxTotal = rx;
                root.txTotal = tx;
                root.lastSample = { rx: rx, tx: tx, time: now };
            }
        }
    }

    Process {
        id: pingQuery
        command: ["ping", "-n", "-q", "-c", "3", "-i", "0.2", "-W", "1", "1.1.1.1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const loss = this.text.match(/(\d+(?:\.\d+)?)% packet loss/);
                const rtt = this.text.match(/= [\d.]+\/([\d.]+)\//);
                root.packetLoss = loss ? Number(loss[1]) : -1;
                root.latency = rtt ? Number(rtt[1]) : -1;
            }
        }
    }

    readonly property string netCtlScript: Quickshell.env("HOME") + "/.config/quickshell/endfield/scripts/net-ctl.sh"

    Process {
        id: statusQuery
        command: [root.netCtlScript, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text;
                if (!text.trim()) {
                    // Mid-reconnect the script reports nothing too; only treat
                    // silence as "no Wi-Fi" once a write is not in flight.
                    if (!root.busy) {
                        root.band = "";
                        root.bandAvailable = [];
                    }
                    return;
                }
                for (const line of text.split("\n")) {
                    const [key, value] = line.split("\t");
                    if (key === "dns")
                        root.dns = value;
                    else if (key === "selected")
                        root.bandSelected = value;
                    else if (key === "band")
                        root.band = value;
                    else if (key === "available")
                        root.bandAvailable = value ? value.split(" ").filter(b => b) : [];
                }
            }
        }
    }

    // Shared by setDns/setBand: only one reassociating write at a time.
    Process {
        id: controlProcess
        onExited: {
            root.busy = false;
            statusQuery.running = true;
        }
    }

    Timer {
        interval: 2000
        running: root.polling
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            gatewayQuery.running = true;
            if (root.interfaceName !== "")
                throughputQuery.running = true;
        }
    }

    Timer {
        interval: 10000
        running: root.polling
        repeat: true
        triggeredOnStart: true
        onTriggered: pingQuery.running = true
    }

    Timer {
        interval: 8000
        running: root.polling
        repeat: true
        triggeredOnStart: true
        onTriggered: statusQuery.running = true
    }
}
