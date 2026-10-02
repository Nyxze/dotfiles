import ".."
import QtQuick
import QtQuick.Layouts

// A labelled group inside a detail page. No frame: the panel is the frame, and
// nesting boxes inside boxes was what made the old stacked layout heavy.
ColumnLayout {
    id: section

    default property alias content: body.data

    property string title: ""

    spacing: Theme.space(2)

    RowLayout {
        Layout.fillWidth: true
        visible: section.title !== ""
        spacing: Theme.space(2)

        // A chamfered Shape this small doesn't rasterize reliably (confirmed
        // by screenshot — it silently draws nothing), so the badge stays a
        // plain square rather than fight a QtQuick Shapes minimum-size quirk.
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Theme.space(2)
            Layout.preferredHeight: Theme.space(2)
            color: Theme.textMuted
        }

        Text {
            text: section.title
            color: Theme.textMuted
            font: Theme.label
        }

        // The long thin rule: a label alone read as a floating caption, this
        // ties it to the row of content it introduces.
        Rectangle {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            implicitHeight: Theme.border
            color: Theme.line
        }
    }

    ColumnLayout {
        id: body
        Layout.fillWidth: true
        spacing: Theme.space(2)
    }
}
