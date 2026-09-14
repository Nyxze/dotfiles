import ".."
import QtQuick
import QtQuick.Layouts

// A labelled group inside a detail page. No frame: the panel is the frame, and
// nesting boxes inside boxes was what made the old stacked layout heavy.
ColumnLayout {
    id: section

    default property alias content: body.data

    property string title: ""

    spacing: 6

    Text {
        visible: section.title !== ""
        text: section.title
        color: Theme.mediumGray
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.capitalization: Font.AllUppercase
        font.weight: Font.DemiBold
        font.letterSpacing: 0.8
    }

    ColumnLayout {
        id: body
        Layout.fillWidth: true
        spacing: 6
    }
}
