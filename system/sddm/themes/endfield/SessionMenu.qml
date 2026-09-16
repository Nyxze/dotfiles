import "components"
import QtQuick

// The session picker, kept out of the login plate: a session is chosen once in
// a while and the password is typed every time, so only one of the two belongs
// in the middle of the screen.
//
// Fills its parent rather than sizing to the trigger, because closing on a
// click anywhere else needs a layer over the whole screen. It is transparent
// to input while shut.
Item {
    id: root

    property var model: null
    property int index: 0
    property bool open: false

    // Written by whichever delegate matches `index`: a model role is only
    // reachable from inside a delegate.
    property string currentName: ""

    signal picked(int index)

    function close() {
        root.open = false;
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.open
        onClicked: root.close()
    }

    Column {
        x: Theme.space(8)
        y: Theme.space(8)
        width: Theme.space(76)
        spacing: Theme.space(2)

        ChamferedRect {
            id: trigger

            width: parent.width
            height: Theme.space(9)
            bottomRight: true
            chamfer: Theme.space(1)
            color: Cursor.item === trigger ? Theme.bgRaised : Theme.bgPanel
            borderColor: root.open ? Theme.accent : Theme.line
            borderWidth: root.open || Cursor.item === trigger ? Theme.borderEmphasis : Theme.border

            Text {
                id: triggerGlyph

                anchors.left: parent.left
                anchors.leftMargin: Theme.space(3)
                anchors.verticalCenter: parent.verticalCenter
                text: "󰆍"
                color: root.open ? Theme.accent : Theme.textMuted
                font: Theme.glyphSmall
            }

            Text {
                anchors.left: triggerGlyph.right
                anchors.leftMargin: Theme.space(3)
                anchors.right: chevron.left
                anchors.rightMargin: Theme.space(2)
                anchors.verticalCenter: parent.verticalCenter
                text: root.currentName
                elide: Text.ElideRight
                color: Theme.textPrimary
                font: Theme.body
            }

            Text {
                id: chevron

                anchors.right: parent.right
                anchors.rightMargin: Theme.space(3)
                anchors.verticalCenter: parent.verticalCenter
                text: root.open ? "󰅃" : "󰅀"
                color: Theme.textMuted
                font: Theme.glyphSmall
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onContainsMouseChanged: if (containsMouse)
                    Cursor.item = trigger
                onClicked: root.open = !root.open
            }
        }

        ChamferedRect {
            width: parent.width
            height: sheet.height + Theme.space(6)
            visible: root.open
            topLeft: true
            bottomRight: true
            chamfer: Theme.space(2)
            color: Theme.bgPanel
            borderColor: Theme.line
            borderWidth: Theme.border

            Column {
                id: sheet

                x: Theme.space(3)
                y: Theme.space(3)
                width: parent.width - Theme.space(6)
                spacing: Theme.space(2)

                SectionLabel {
                    width: parent.width
                    text: "Session"
                }

                Column {
                    width: parent.width
                    spacing: Theme.space(1)

                    Repeater {
                        model: root.model

                        ListRow {
                            required property int index
                            required property string name

                            width: parent.width
                            label: name
                            glyph: "󰆍"
                            selected: index === root.index

                            onSelectedChanged: if (selected)
                                root.currentName = name
                            Component.onCompleted: if (selected)
                                root.currentName = name

                            onActivated: {
                                root.picked(index);
                                root.close();
                            }
                        }
                    }
                }
            }
        }
    }
}
