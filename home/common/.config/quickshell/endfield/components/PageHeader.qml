import ".."
import QtQuick
import QtQuick.Layouts

// The first line of a detail page: what it is about, what state it is in, and
// the controls that act on the whole page. Children land on the trailing edge.
RowLayout {
    id: header

    default property alias actions: trailing.data

    property string glyph: ""
    property string title: ""
    property string subtitle: ""
    property bool dimmed: false

    spacing: Theme.space(3)

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: header.glyph
        color: header.dimmed ? Theme.line : Theme.accent
        font: Theme.glyphLarge
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.space(1)

        Text {
            Layout.fillWidth: true
            text: header.title
            elide: Text.ElideRight
            color: Theme.textPrimary
            font: Theme.h3
        }

        Text {
            Layout.fillWidth: true
            visible: header.subtitle !== ""
            text: header.subtitle
            elide: Text.ElideRight
            color: Theme.textMuted
            font: Theme.micro
        }
    }

    RowLayout {
        id: trailing
        Layout.alignment: Qt.AlignVCenter
        spacing: Theme.space(2)
    }
}
