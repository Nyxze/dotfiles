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

    // No MouseArea of its own — the row is the cursor stop, but a hover claims
    // it only through whichever child the pointer actually sits over.
    readonly property bool navigable: true
    readonly property bool hasCursor: Cursor.item === row

    function navActivate() {
        row.iconActivated();
    }

    function navAdjust(step) {
        row.moved(Math.max(0, Math.min(1, row.value + step * 0.05)));
    }

    spacing: Theme.space(3)

    IconButton {
        cursorTarget: row
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
        Layout.minimumWidth: Theme.space(9)
        horizontalAlignment: Text.AlignRight
        text: Math.round(row.value * 100) + "%"
        color: row.dimmed ? Theme.line : Theme.textSecondary
        font: Theme.body
    }

    IconButton {
        cursorTarget: row
        visible: row.expandable
        glyph: "›"
        onActivated: row.expanded()
    }
}
