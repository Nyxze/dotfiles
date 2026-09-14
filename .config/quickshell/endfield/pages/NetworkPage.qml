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

    spacing: 16

    // Scanning costs power, so it runs only while this page is on screen.
    Component.onCompleted: NetworkService.setScanning(true)
    Component.onDestruction: NetworkService.setScanning(false)

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: NetworkService.ipv4 || NetworkService.status
            elide: Text.ElideRight
            color: Theme.lightGray
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }

        IconButton {
            enabled: NetworkService.wifiEnabled
            opacity: enabled ? 1 : 0.4
            glyph: "󰑐"
            onActivated: {
                NetworkService.setScanning(false);
                NetworkService.setScanning(true);
            }
        }

        IconButton {
            glyph: NetworkService.wifiEnabled ? "󰖩" : "󰖪"
            onActivated: NetworkService.toggleWifi()
        }
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
        visible: NetworkService.wifi !== null
        title: "Wi-Fi"

        Text {
            Layout.fillWidth: true
            visible: !NetworkService.wifiEnabled
            text: "Wi-Fi is off"
            color: Theme.overlay
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        Text {
            Layout.fillWidth: true
            visible: NetworkService.wifiEnabled && NetworkService.networks.length === 0
            text: "Scanning…"
            color: Theme.overlay
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        Repeater {
            model: NetworkService.wifiEnabled ? NetworkService.networks : []

            ColumnLayout {
                id: entry

                required property var modelData

                readonly property bool prompting: page.prompting === modelData

                Layout.fillWidth: true
                spacing: 4

                Connections {
                    target: entry.modelData

                    function onConnectionFailed(reason) {
                        page.failure = ConnectionFailReason.toString(reason);
                        if (reason === ConnectionFailReason.NoSecrets)
                            page.prompting = entry.modelData;
                    }
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
                    Layout.leftMargin: 10
                    Layout.rightMargin: 10
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
                    Layout.leftMargin: 10
                    visible: page.failure !== "" && entry.modelData.state === ConnectionState.Disconnected
                        && (entry.prompting || entry.modelData.known)
                    text: page.failure
                    color: Theme.critical
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }
        }
    }
}
