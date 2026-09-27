import ".."
import "../components"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page

    readonly property var modes: [
        {
            mode: "extend",
            glyph: "󰍺",
            label: "Extend",
            detail: "EXTERNAL + LAPTOP"
        },
        {
            mode: "mirror",
            glyph: "󱒃",
            label: "Mirror",
            detail: "SAME IMAGE"
        },
        {
            mode: "external",
            glyph: "󰍹",
            label: "External only",
            detail: "MAIN DISPLAY"
        },
        {
            mode: "internal",
            glyph: "󰌢",
            label: "Internal only",
            detail: "LAPTOP"
        }
    ]

    spacing: Theme.space(4)

    Component.onCompleted: DisplayService.refresh()

    PageHeader {
        Layout.fillWidth: true
        glyph: "󰍺"
        title: "Display mode"
        subtitle: DisplayService.busy ? "APPLYING" : DisplayService.label(DisplayService.mode)
        dimmed: DisplayService.busy
    }

    Section {
        Layout.fillWidth: true
        title: "Layout"

        Repeater {
            model: page.modes

            ListRow {
                required property var modelData

                Layout.fillWidth: true
                glyph: modelData.glyph
                label: modelData.label
                trailing: modelData.detail
                selected: DisplayService.mode === modelData.mode
                onActivated: DisplayService.setMode(modelData.mode)
            }
        }
    }
}
