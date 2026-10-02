import ".."
import "../components"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    readonly property bool muted: AudioService.mutedOf(AudioService.sink)
    readonly property real volume: AudioService.volumeOf(AudioService.sink)

    spacing: Theme.space(4)

    // Port availability polling costs a pactl call every 5s; only worth it
    // while this page is actually on screen.
    Component.onCompleted: AudioService.setProbing(true)
    Component.onDestruction: AudioService.setProbing(false)

    PageHeader {
        Layout.fillWidth: true
        glyph: AudioService.sinkGlyph(AudioService.sink)
        title: AudioService.label(AudioService.sink) || "No output"
        subtitle: muted ? "MUTED" : Math.round(volume * 100) + "%"
        dimmed: muted

        ToggleSwitch {
            checked: !muted
            onToggled: AudioService.toggleMute(AudioService.sink)
        }
    }

    Section {
        Layout.fillWidth: true
        title: "Devices"

        Text {
            Layout.fillWidth: true
            visible: AudioService.sinks.length === 0
            text: "No output device"
            color: Theme.line
            font: Theme.body
        }

        Repeater {
            model: AudioService.sinks

            ListRow {
                required property var modelData

                Layout.fillWidth: true
                glyph: AudioService.sinkGlyph(modelData)
                label: AudioService.label(modelData)
                trailing: Math.round(AudioService.volumeOf(modelData) * 100) + "%"
                selected: AudioService.sink && modelData.id === AudioService.sink.id
                onActivated: AudioService.setSink(modelData)
            }
        }
    }

    Section {
        Layout.fillWidth: true
        visible: AudioService.streams.length > 0
        title: "Applications"

        Repeater {
            model: AudioService.streams

            LevelRow {
                required property var modelData

                Layout.fillWidth: true
                glyph: AudioService.mutedOf(modelData) ? "󰝟" : "󰕾"
                label: AudioService.streamLabel(modelData)
                value: AudioService.volumeOf(modelData)
                maximum: 1.5
                dimmed: AudioService.mutedOf(modelData)
                onGlyphActivated: AudioService.toggleMute(modelData)
                onMoved: level => AudioService.setVolume(modelData, level)
            }
        }
    }
}
