import ".."
import "../components"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    readonly property bool muted: AudioService.mutedOf(AudioService.source)
    readonly property real volume: AudioService.volumeOf(AudioService.source)

    spacing: Theme.space(4)

    PageHeader {
        Layout.fillWidth: true
        glyph: AudioService.sourceGlyph(AudioService.source)
        title: AudioService.label(AudioService.source) || "No input"
        subtitle: muted ? "MUTED" : Math.round(volume * 100) + "%"
        dimmed: muted

        ToggleSwitch {
            checked: !muted
            onToggled: AudioService.toggleMute(AudioService.source)
        }
    }

    Section {
        Layout.fillWidth: true
        title: "Devices"

        Text {
            Layout.fillWidth: true
            visible: AudioService.sources.length === 0
            text: "No input device"
            color: Theme.line
            font: Theme.body
        }

        Repeater {
            model: AudioService.sources

            ListRow {
                required property var modelData

                Layout.fillWidth: true
                glyph: AudioService.sourceGlyph(modelData)
                label: AudioService.label(modelData)
                trailing: Math.round(AudioService.volumeOf(modelData) * 100) + "%"
                selected: AudioService.source && modelData.id === AudioService.source.id
                onActivated: AudioService.setSource(modelData)
            }
        }
    }

    Section {
        Layout.fillWidth: true
        visible: AudioService.recorders.length > 0
        title: "Listening"

        Repeater {
            model: AudioService.recorders

            ListRow {
                required property var modelData

                Layout.fillWidth: true
                glyph: "󰍬"
                label: AudioService.streamLabel(modelData)
                trailing: AudioService.mutedOf(modelData) ? "muted" : ""
            }
        }
    }
}
