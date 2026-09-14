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

    spacing: 12

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: header.glyph
        color: header.dimmed ? Theme.overlay : Theme.brightYellow
        font.family: Theme.monoFamily
        font.pixelSize: 24
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 1

        Text {
            Layout.fillWidth: true
            text: header.title
            elide: Text.ElideRight
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }

        Text {
            Layout.fillWidth: true
            visible: header.subtitle !== ""
            text: header.subtitle
            elide: Text.ElideRight
            color: Theme.mediumGray
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.capitalization: Font.AllUppercase
            font.weight: Font.DemiBold
            font.letterSpacing: 0.8
        }
    }

    RowLayout {
        id: trailing
        Layout.alignment: Qt.AlignVCenter
        spacing: 6
    }
}
