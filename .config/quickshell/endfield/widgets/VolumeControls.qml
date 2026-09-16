import ".."
import "../components"
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

// The two levels worth keeping permanently on screen. Everything else about
// audio lives behind the chevrons.
ColumnLayout {
    id: controls

    signal pageRequested(string page)

    spacing: Theme.space(2)

    SliderRow {
        Layout.fillWidth: true

        glyph: AudioService.mutedOf(AudioService.sink) ? "󰖁" : "󰕾"
        value: AudioService.volumeOf(AudioService.sink)
        dimmed: AudioService.mutedOf(AudioService.sink)
        expandable: true

        onIconActivated: AudioService.toggleMute(AudioService.sink)
        onMoved: level => AudioService.setVolume(AudioService.sink, level)
        onExpanded: controls.pageRequested("output")
    }

    SliderRow {
        Layout.fillWidth: true

        glyph: AudioService.mutedOf(AudioService.source) ? "󰍭" : "󰍬"
        value: AudioService.volumeOf(AudioService.source)
        dimmed: AudioService.mutedOf(AudioService.source)
        expandable: true

        onIconActivated: AudioService.toggleMute(AudioService.source)
        onMoved: level => AudioService.setVolume(AudioService.source, level)
        onExpanded: controls.pageRequested("input")
    }

    // Live input level, so a dead microphone reads differently from a quiet one.
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.space(9)
        Layout.rightMargin: Theme.space(12)
        implicitHeight: Theme.space(1)

        PwNodePeakMonitor {
            id: meter
            node: AudioService.source
            enabled: AudioService.source !== null
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.bgDeep

            Rectangle {
                width: parent.width * Math.min(1, meter.peak * 2)
                height: parent.height
                color: meter.peak > 0.45 ? Theme.danger : Theme.success

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.durPress
                    }
                }
            }
        }
    }
}
