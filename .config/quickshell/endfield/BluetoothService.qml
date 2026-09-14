pragma Singleton

import Quickshell
import Quickshell.Bluetooth
import QtQuick

// Single view onto BlueZ. Devices report a state change a beat after the
// request, so `pending` tracks what we just asked for until the real state
// agrees with it (or 20s pass and we give up waiting).
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter !== null && adapter.enabled
    readonly property bool discovering: adapter !== null && adapter.discovering

    readonly property var devices: Bluetooth.devices.values

    // Connected first, then remembered, then unknown, each sorted by label so
    // a scan turning up something new does not reshuffle the rest.
    readonly property var connected: devices.filter(d => d.connected).sort(byLabel)
    readonly property var paired: devices.filter(d => !d.connected && remembered(d)).sort(byLabel)
    readonly property var discovered: devices.filter(d => !d.connected && !remembered(d)).sort(byLabel)

    property var pending: ({})
    property var pendingSince: ({})

    // Previous connected addresses, to detect a new one for the audio hand-off.
    property var lastConnected: []
    property string handoffAddress: ""
    property int handoffAttempts: 0

    function remembered(device) {
        return device.paired || device.bonded || device.trusted;
    }

    function byLabel(a, b) {
        return label(a).localeCompare(label(b));
    }

    function label(device) {
        return device.deviceName || device.name || device.address;
    }

    function glyph(device) {
        const l = label(device).toLowerCase();
        if (/headphone|headset|earbud|earphone|airpod/.test(l))
            return "󰋋";
        if (/mouse/.test(l))
            return "󰥰";
        if (/keyboard/.test(l))
            return "󰌌";
        if (/speaker/.test(l))
            return "󰄋";
        return device.connected ? "󰂱" : "󰂯";
    }

    function statusOf(device) {
        const action = pending[device.address];
        if (action === "forgetting")
            return "Forgetting…";
        if (action === "disconnecting")
            return "Disconnecting…";
        if (action === "connecting")
            return "Connecting…";
        if (device.state === BluetoothDeviceState.Disconnecting)
            return "Disconnecting…";
        if (device.state === BluetoothDeviceState.Connecting || device.pairing)
            return "Connecting…";
        if (device.connected && device.batteryAvailable)
            return Math.round(device.battery * 100) + "%";
        if (device.connected)
            return "Connected";
        return "";
    }

    function activate(device) {
        if (pending[device.address])
            return;
        if (device.connected) {
            setPending(device.address, "disconnecting");
            device.disconnect();
        } else if (remembered(device)) {
            setPending(device.address, "connecting");
            device.connect();
        } else {
            setPending(device.address, "connecting");
            device.pair();
        }
    }

    function forget(device) {
        setPending(device.address, "forgetting");
        device.forget();
    }

    function toggleAdapter() {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }

    // Called on page show/hide, same as NetworkService.setScanning.
    function setDiscovering(on) {
        if (!adapter || !adapter.enabled)
            return;
        adapter.discovering = on;
    }

    function setPending(address, action) {
        const next = Object.assign({}, pending);
        next[address] = action;
        pending = next;
        const since = Object.assign({}, pendingSince);
        since[address] = Date.now();
        pendingSince = since;
    }

    // Reassigning the whole map (rather than mutating in place) is what makes
    // QML notice the change.
    function reconcilePending() {
        const addresses = Object.keys(pending);
        if (addresses.length === 0)
            return;
        const now = Date.now();
        const next = Object.assign({}, pending);
        const since = Object.assign({}, pendingSince);
        let changed = false;
        for (const address of addresses) {
            const action = pending[address];
            const device = devices.find(d => d.address === address);
            const stale = now - (pendingSince[address] || 0) > 20000;
            const settled = (action === "connecting" && device && device.connected)
                || (action === "disconnecting" && device && !device.connected)
                || (action === "forgetting" && !device);
            if (stale || settled) {
                delete next[address];
                delete since[address];
                changed = true;
            }
        }
        if (changed) {
            pending = next;
            pendingSince = since;
        }
    }

    onDevicesChanged: reconcilePending()
    onConnectedChanged: {
        reconcilePending();
        const addresses = connected.map(d => d.address);
        const added = addresses.find(a => lastConnected.indexOf(a) < 0);
        lastConnected = addresses;
        if (added) {
            handoffAddress = added;
            handoffAttempts = 0;
            handoffTimer.restart();
        }
    }

    // Pending entries a dropped BlueZ request would otherwise leave stuck.
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.reconcilePending()
    }

    // PipeWire's bluez sink shows up a second or two after BlueZ reports the
    // connection, hence the poll instead of reacting once.
    Timer {
        id: handoffTimer
        interval: 750
        repeat: true
        onTriggered: {
            handoffAttempts++;
            const needle = root.handoffAddress.toUpperCase().replace(/:/g, "_");
            const sink = AudioService.sinks.find(s => (s.name || "").toUpperCase().includes(needle));
            if (sink) {
                AudioService.setSink(sink);
                stop();
                return;
            }
            if (handoffAttempts >= 8)
                stop();
        }
    }
}
