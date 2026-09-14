import ".."
import "../components"
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

Card {
    id: mic

    // Capture devices, as opposed to recording streams, which carry isStream.
    readonly property var devices: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio)
    readonly property var source: Pipewire.defaultAudioSource

    function label(node) {
        return node.description || node.nickname || node.name;
    }

    title: "Microphone"

    PwObjectTracker {
        objects: Pipewire.nodes.values
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        IconButton {
            glyph: mic.source && mic.source.audio && mic.source.audio.muted ? "󰍭" : "󰍬"
            onActivated: {
                if (mic.source && mic.source.audio)
                    mic.source.audio.muted = !mic.source.audio.muted;
            }
        }

        LevelSlider {
            Layout.fillWidth: true
            value: mic.source && mic.source.audio ? mic.source.audio.volume : 0
            dimmed: mic.source && mic.source.audio ? mic.source.audio.muted : false
            onMoved: level => {
                if (mic.source && mic.source.audio)
                    mic.source.audio.volume = level;
            }
        }

        Text {
            Layout.minimumWidth: 38
            horizontalAlignment: Text.AlignRight
            text: mic.source && mic.source.audio ? Math.round(mic.source.audio.volume * 100) + "%" : "--"
            color: Theme.lightGray
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }
    }

    // Live input level, so you can tell a dead microphone from a quiet one.
    Item {
        Layout.fillWidth: true
        implicitHeight: 6

        PwNodePeakMonitor {
            id: meter
            node: mic.source
            enabled: mic.source !== null
        }

        Rectangle {
            anchors.fill: parent
            radius: 3
            color: Theme.base

            Rectangle {
                width: parent.width * Math.min(1, meter.peak * 2)
                height: parent.height
                radius: parent.radius
                color: meter.peak > 0.45 ? Theme.critical : Theme.success

                Behavior on width {
                    NumberAnimation {
                        duration: 60
                    }
                }
            }
        }
    }

    Repeater {
        model: mic.devices

        Rectangle {
            required property var modelData

            readonly property bool isDefault: mic.source && modelData.id === mic.source.id

            Layout.fillWidth: true
            implicitHeight: 30
            radius: 7
            color: deviceMouse.containsMouse ? Theme.oliveGreen : (isDefault ? Theme.base : "transparent")

            Text {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: mic.label(parent.modelData)
                elide: Text.ElideRight
                color: deviceMouse.containsMouse ? Theme.base : (parent.isDefault ? Theme.brightYellow : Theme.lightGray)
                font.family: Theme.fontFamily
                font.pixelSize: 13
            }

            MouseArea {
                id: deviceMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Pipewire.preferredDefaultAudioSource = parent.modelData
            }
        }
    }
}
