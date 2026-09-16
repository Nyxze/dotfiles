import ".."
import "../components"
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page

    // The network waiting on a passphrase, and the last connection error.
    property var prompting: null
    property string failure: ""

    function activate(network) {
        failure = "";
        prompting = null;
        if (network.stateChanging)
            return;
        if (network.connected) {
            network.disconnect();
            return;
        }
        // A saved network already has its secret; an open one needs none.
        if (network.known || !NetworkService.secured(network)) {
            network.connect();
            return;
        }
        prompting = network;
    }

    function describe(network) {
        if (network.stateChanging)
            return ConnectionState.toString(network.state).toLowerCase() + "…";
        if (network.connected)
            return "connected";
        if (network.known)
            return "saved";
        return NetworkService.securityLabel(network);
    }

    function groupTitle(index) {
        const list = NetworkService.networks;
        const here = list[index].known;
        if (index > 0 && list[index - 1].known === here)
            return "";
        return here ? "Saved" : "Available";
    }

    spacing: Theme.space(4)

    // Scanning and the detail probes both cost power, so both run only while
    // this page is on screen.
    Component.onCompleted: {
        NetworkService.setScanning(true);
        NetworkService.setPolling(true);
    }
    Component.onDestruction: {
        NetworkService.setScanning(false);
        NetworkService.setPolling(false);
    }

    PageHeader {
        Layout.fillWidth: true
        glyph: NetworkService.glyph
        title: {
            if (NetworkService.active)
                return NetworkService.linkDetail
                    ? NetworkService.active.name + " (" + NetworkService.linkDetail + ")"
                    : NetworkService.active.name;
            if (NetworkService.wiredUp)
                return NetworkService.linkDetail
                    ? "Ethernet (" + NetworkService.linkDetail + ")"
                    : "Ethernet";
            return "Not connected";
        }
        subtitle: NetworkService.reach.toUpperCase()
        dimmed: !NetworkService.active && !NetworkService.wiredUp

        IconButton {
            enabled: NetworkService.wifiEnabled
            opacity: enabled ? 1 : 0.4
            glyph: "󰑐"
            onActivated: {
                NetworkService.setScanning(false);
                NetworkService.setScanning(true);
            }
        }

        ToggleSwitch {
            checked: NetworkService.wifiEnabled
            onToggled: NetworkService.toggleWifi()
        }
    }

    DetailGrid {
        Layout.fillWidth: true
        visible: NetworkService.active !== null || NetworkService.wiredUp
        entries: [
            { label: "Ping", value: NetworkService.formatLatency(NetworkService.latency) },
            { label: "Loss", value: NetworkService.formatLoss(NetworkService.packetLoss) },
            { label: "Down", value: NetworkService.formatRate(NetworkService.rxRate) },
            { label: "Up", value: NetworkService.formatRate(NetworkService.txRate) },
            { label: "Received", value: NetworkService.formatBytes(NetworkService.rxTotal) },
            { label: "Sent", value: NetworkService.formatBytes(NetworkService.txTotal) },
            { label: "IP", value: NetworkService.ipv4 || "—", copy: NetworkService.ipv4 !== "" },
            { label: "Gateway", value: NetworkService.gateway || "—", copy: NetworkService.gateway !== "" }
        ]
    }

    Section {
        Layout.fillWidth: true
        visible: NetworkService.wired !== null
        title: "Wired"

        ListRow {
            Layout.fillWidth: true
            label: NetworkService.wired ? NetworkService.wired.name : ""
            trailing: {
                if (!NetworkService.wired)
                    return "";
                if (!NetworkService.wired.hasLink)
                    return "unplugged";
                return NetworkService.wired.connected
                    ? NetworkService.wired.linkSpeed + " Mb/s"
                    : "disconnected";
            }
            selected: NetworkService.wiredUp
            onActivated: {
                if (NetworkService.wiredUp)
                    NetworkService.wired.disconnect();
            }
        }
    }

    Section {
        Layout.fillWidth: true
        title: "Band"
        visible: NetworkService.bandAvailable.length > 1

        PillRow {
            Layout.fillWidth: true
            // Pinning a band reassociates and takes several seconds.
            enabled: !NetworkService.busy
            options: [{ key: "auto", label: "Auto" }].concat(
                NetworkService.bandAvailable.map(b => ({ key: b, label: b + " GHz" })))
            current: NetworkService.bandSelected
            onPicked: key => NetworkService.setBand(key)
        }
    }

    Section {
        Layout.fillWidth: true
        title: "DNS"
        // Only the active Wi-Fi profile can be rewritten, not a wired one.
        visible: NetworkService.active !== null

        PillRow {
            Layout.fillWidth: true
            enabled: !NetworkService.busy
            options: [
                { key: "dhcp", label: "DHCP" },
                { key: "cloudflare", label: "Cloudflare" },
                { key: "google", label: "Google" },
                { key: "quad9", label: "Quad9" }
            ]
            current: NetworkService.dns
            onPicked: key => NetworkService.setDns(key)
        }
    }

    // No section title: the Saved/Available headings inside the list already
    // label it, and two stacked headers read as a mistake.
    Section {
        Layout.fillWidth: true
        visible: NetworkService.wifi !== null

        Text {
            Layout.fillWidth: true
            visible: !NetworkService.wifiEnabled
            text: "Wi-Fi is off"
            color: Theme.line
            font: Theme.body
        }

        Text {
            Layout.fillWidth: true
            visible: NetworkService.wifiEnabled && NetworkService.networks.length === 0
            text: "Scanning…"
            color: Theme.line
            font: Theme.body
        }

        Repeater {
            model: NetworkService.wifiEnabled ? NetworkService.networks : []

            ColumnLayout {
                id: entry

                required property var modelData
                required property int index

                readonly property bool prompting: page.prompting === modelData

                Layout.fillWidth: true
                spacing: Theme.space(1)

                Connections {
                    target: entry.modelData

                    function onConnectionFailed(reason) {
                        page.failure = ConnectionFailReason.toString(reason);
                        if (reason === ConnectionFailReason.NoSecrets)
                            page.prompting = entry.modelData;
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.space(1)
                    text: page.groupTitle(entry.index)
                    visible: text !== ""
                    color: Theme.textMuted
                    font: Theme.label
                }

                ListRow {
                    Layout.fillWidth: true
                    glyph: NetworkService.signalGlyph(entry.modelData.signalStrength)
                    label: entry.modelData.name
                    trailing: page.describe(entry.modelData)
                    selected: entry.modelData.connected
                    actionGlyph: entry.modelData.known && !entry.modelData.connected ? "󰅖" : ""
                    onActivated: page.activate(entry.modelData)
                    onActionActivated: entry.modelData.forget()
                }

                PasswordField {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.space(3)
                    Layout.rightMargin: Theme.space(3)
                    visible: entry.prompting
                    placeholder: "Passphrase for " + entry.modelData.name

                    onVisibleChanged: {
                        if (visible)
                            focusInput();
                        else
                            clear();
                    }

                    onAccepted: value => {
                        page.prompting = null;
                        entry.modelData.connectWithPsk(value);
                    }
                    onCancelled: page.prompting = null
                }

                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.space(3)
                    visible: page.failure !== "" && entry.modelData.state === ConnectionState.Disconnected
                        && (entry.prompting || entry.modelData.known)
                    text: page.failure
                    color: Theme.danger
                    font: Theme.bodySmall
                }
            }
        }
    }
}
