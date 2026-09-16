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

    spacing: Theme.space(1)

    Repeater {
        model: rail.pages

        ChamferedRect {
            id: tab

            required property var modelData

            readonly property bool active: modelData.key === rail.current

            readonly property bool navigable: true
            readonly property bool hasCursor: Cursor.item === tab

            function navActivate() {
                rail.selected(tab.modelData.key);
            }

            Layout.fillWidth: true
            implicitHeight: Theme.space(9)
            // The measured device: the active tab cuts its two top corners.
            topLeft: true
            topRight: true
            chamfer: 4
            color: {
                if (tab.active)
                    return Theme.bgRaised;
                return tab.hasCursor ? Theme.line : "transparent";
            }

            borderWidth: tab.hasCursor ? Theme.borderEmphasis : 0
            borderColor: Theme.accent

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durHover
                }
            }

            Text {
                anchors.centerIn: parent
                text: tab.modelData.glyph
                color: {
                    if (tab.active)
                        return Theme.accent;
                    return tab.hasCursor ? Theme.textPrimary : Theme.textMuted;
                }
                font: Theme.glyphSmall
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
