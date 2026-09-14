import ".."
import "../components"
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

Card {
    id: bt

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter ? adapter.enabled : false

    // Paired devices first and connected ones above those, so the list does not
    // reshuffle every time a scan turns up something new.
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

    title: "Bluetooth"

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: {
                if (!bt.adapter)
                    return "No adapter";
                if (!bt.powered)
                    return "Off";
                return bt.adapter.discovering ? "Scanning…" : bt.adapter.name;
            }
            color: Theme.mediumGray
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        IconButton {
            enabled: bt.powered
            opacity: enabled ? 1 : 0.4
            glyph: "󰑐"
            onActivated: {
                if (bt.adapter)
                    bt.adapter.discovering = !bt.adapter.discovering;
            }
        }

        IconButton {
            glyph: bt.powered ? "󰂯" : "󰂲"
            onActivated: {
                if (bt.adapter)
                    bt.adapter.enabled = !bt.adapter.enabled;
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: bt.powered && bt.devices.length === 0
        text: "No device"
        color: Theme.overlay
        font.family: Theme.fontFamily
        font.pixelSize: 12
    }

    Repeater {
        model: bt.powered ? bt.devices : []

        Rectangle {
            id: row

            required property var modelData

            readonly property bool busy: modelData.state === BluetoothDeviceState.Connecting
                || modelData.state === BluetoothDeviceState.Disconnecting

            Layout.fillWidth: true
            implicitHeight: 34
            radius: 7
            color: rowMouse.containsMouse ? Theme.oliveGreen : (modelData.connected ? Theme.base : "transparent")

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: row.modelData.connected ? "󰂱" : "󰂯"
                    color: rowMouse.containsMouse ? Theme.base : (row.modelData.connected ? Theme.brightYellow : Theme.mediumGray)
                    font.family: Theme.monoFamily
                    font.pixelSize: 14
                }

                Text {
                    Layout.fillWidth: true
                    text: row.modelData.deviceName || row.modelData.name || row.modelData.address
                    elide: Text.ElideRight
                    color: rowMouse.containsMouse ? Theme.base : (row.modelData.connected ? Theme.text : Theme.lightGray)
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }

                Text {
                    visible: row.modelData.batteryAvailable
                    text: Math.round(row.modelData.battery * 100) + "%"
                    color: rowMouse.containsMouse ? Theme.base : Theme.mediumGray
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }

                Text {
                    visible: row.busy
                    text: "…"
                    color: rowMouse.containsMouse ? Theme.base : Theme.feintYellow
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (row.busy)
                        return;
                    if (row.modelData.connected)
                        row.modelData.disconnect();
                    else if (row.modelData.paired)
                        row.modelData.connect();
                    else
                        row.modelData.pair();
                }
            }
        }
    }
}
