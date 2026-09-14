import ".."
import QtQuick
import QtQuick.Layouts

// Icon, slider, readout and an optional chevron to the matching detail page.
RowLayout {
    id: row

    property string glyph: ""
    property real value: 0
    property bool dimmed: false
    property bool expandable: false

    signal iconActivated
    signal moved(real level)
    signal expanded

    spacing: 10

    IconButton {
        glyph: row.glyph
        onActivated: row.iconActivated()
    }

    LevelSlider {
        Layout.fillWidth: true
        value: row.value
        dimmed: row.dimmed
        onMoved: level => row.moved(level)
    }

    Text {
        Layout.minimumWidth: 36
        horizontalAlignment: Text.AlignRight
        text: Math.round(row.value * 100) + "%"
        color: row.dimmed ? Theme.overlay : Theme.lightGray
        font.family: Theme.fontFamily
        font.pixelSize: 13
    }

    IconButton {
        visible: row.expandable
        glyph: "›"
        onActivated: row.expanded()
    }
}
