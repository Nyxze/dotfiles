import ".."
import "../components"
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

Card {
    id: audio

    // Output devices and playback streams differ only by isStream: a sink with
    // isStream is an application feeding a sink, not a device.
    readonly property var devices: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isSink && n.isStream && n.audio)
    readonly property var sink: Pipewire.defaultAudioSink

    function label(node) {
        return node.description || node.nickname || node.name;
    }

    title: "Audio"

    // Without a tracker the audio properties of these nodes never populate.
    PwObjectTracker {
        objects: Pipewire.nodes.values
    }

    // --- Default sink volume ---

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        IconButton {
            glyph: audio.sink && audio.sink.audio && audio.sink.audio.muted ? "󰖁" : "󰕾"
            onActivated: {
                if (audio.sink && audio.sink.audio)
                    audio.sink.audio.muted = !audio.sink.audio.muted;
            }
        }

        LevelSlider {
            Layout.fillWidth: true
            value: audio.sink && audio.sink.audio ? audio.sink.audio.volume : 0
            dimmed: audio.sink && audio.sink.audio ? audio.sink.audio.muted : false
            onMoved: level => {
                if (audio.sink && audio.sink.audio)
                    audio.sink.audio.volume = level;
            }
        }

        Text {
            Layout.minimumWidth: 38
            horizontalAlignment: Text.AlignRight
            text: audio.sink && audio.sink.audio ? Math.round(audio.sink.audio.volume * 100) + "%" : "--"
            color: Theme.lightGray
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }
    }

    // --- Output device picker ---

    Repeater {
        model: audio.devices

        Rectangle {
            required property var modelData

            readonly property bool isDefault: audio.sink && modelData.id === audio.sink.id

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
                text: audio.label(parent.modelData)
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
                onClicked: Pipewire.preferredDefaultAudioSink = parent.modelData
            }
        }
    }

    // --- Per-application volume ---

    Repeater {
        model: audio.streams

        RowLayout {
            required property var modelData

            Layout.fillWidth: true
            spacing: 10

            Text {
                Layout.preferredWidth: 90
                text: audio.label(parent.modelData)
                elide: Text.ElideRight
                color: Theme.mediumGray
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }

            LevelSlider {
                Layout.fillWidth: true
                value: parent.modelData.audio ? parent.modelData.audio.volume : 0
                dimmed: parent.modelData.audio ? parent.modelData.audio.muted : false
                onMoved: level => {
                    if (parent.modelData.audio)
                        parent.modelData.audio.volume = level;
                }
            }
        }
    }
}
