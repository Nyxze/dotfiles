import ".."
import QtQuick
import QtQuick.Layouts

// The panel's own navigation. Every page is one click away and, more to the
// point, visible: the chevrons on the tiles and sliders are shortcuts, not the
// only way in.
RowLayout {
    id: rail

    property var pages: []
    property string current: ""

    signal selected(string key)

    spacing: 2

    Repeater {
        model: rail.pages

        Rectangle {
            id: tab

            required property var modelData

            readonly property bool active: modelData.key === rail.current

            readonly property bool navigable: true
            readonly property bool hasCursor: Cursor.item === tab

            function navActivate() {
                rail.selected(tab.modelData.key);
            }

            Layout.fillWidth: true
            implicitHeight: 34
            radius: 8
            color: {
                if (tab.active)
                    return Theme.charcoal;
                return tab.hasCursor ? Theme.overlay : "transparent";
            }

            Behavior on color {
                ColorAnimation {
                    duration: 90
                }
            }

            Text {
                anchors.centerIn: parent
                text: tab.modelData.glyph
                color: {
                    if (tab.active)
                        return Theme.brightYellow;
                    return tab.hasCursor ? Theme.text : Theme.mediumGray;
                }
                font.family: Theme.monoFamily
                font.pixelSize: 16
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onContainsMouseChanged: if (containsMouse) Cursor.item = tab
                onClicked: rail.selected(tab.modelData.key)
            }
        }
    }
}
