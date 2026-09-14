import ".."
import QtQuick
import QtQuick.Layouts

// A titled section inside a panel. Children stack vertically inside the frame;
// non-visual children (trackers, processes) are fine too.
ColumnLayout {
    id: card

    default property alias content: body.data

    property string title: ""
    property int innerSpacing: 10

    spacing: 6

    Text {
        visible: card.title !== ""
        text: card.title
        color: Theme.mediumGray
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.capitalization: Font.AllUppercase
        font.weight: Font.DemiBold
        font.letterSpacing: 0.8
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: body.implicitHeight + 24
        radius: Theme.radius
        color: Theme.charcoal

        ColumnLayout {
            id: body
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: card.innerSpacing
        }
    }
}
