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
            model: AudioService.sinks

            ListRow {
                required property var modelData

                Layout.fillWidth: true
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

            RowLayout {
                required property var modelData

                Layout.fillWidth: true
                spacing: 10

                Text {
                    Layout.preferredWidth: 96
                    text: AudioService.label(modelData)
                    elide: Text.ElideRight
                    color: Theme.lightGray
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }

                LevelSlider {
                    Layout.fillWidth: true
                    value: AudioService.volumeOf(modelData)
                    dimmed: AudioService.mutedOf(modelData)
                    onMoved: level => AudioService.setVolume(modelData, level)
                }

                Text {
                    Layout.minimumWidth: 36
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(AudioService.volumeOf(modelData) * 100) + "%"
                    color: Theme.mediumGray
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
            }
        }
    }
}
