import ".."
import "../components"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: 16

    Section {
        Layout.fillWidth: true
        title: "Devices"

        Repeater {
            model: AudioService.sources

            ListRow {
                required property var modelData

                Layout.fillWidth: true
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
                label: AudioService.label(modelData)
                trailing: AudioService.mutedOf(modelData) ? "muted" : ""
            }
        }
    }
}
