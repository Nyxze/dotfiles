import ".."
import QtQuick

Rectangle {
    id: field

    property alias text: input.text
    property string placeholder: "Search"
    readonly property bool navigable: true
    readonly property bool hasCursor: Cursor.item === field

    function navActivate() {
        input.forceActiveFocus();
    }

    function clear() {
        input.text = "";
    }

    implicitHeight: Theme.space(9)
    color: Theme.bgDeep
    border.width: input.activeFocus || hasCursor ? Theme.borderEmphasis : Theme.border
    border.color: input.activeFocus || hasCursor ? Theme.accent : Theme.line

    Text {
        id: glyph

        anchors.left: parent.left
        anchors.leftMargin: Theme.space(3)
        anchors.verticalCenter: parent.verticalCenter
        text: "󰍉"
        color: Theme.textMuted
        font: Theme.glyphSmall
    }

    TextInput {
        id: input

        anchors.left: glyph.right
        anchors.right: clearButton.left
        anchors.leftMargin: Theme.space(2)
        anchors.rightMargin: Theme.space(2)
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        color: Theme.textPrimary
        selectionColor: Theme.accent
        selectedTextColor: Theme.onAccent
        font: Theme.body
        onActiveFocusChanged: Cursor.editing = activeFocus
        Component.onDestruction: {
            if (activeFocus) {
                Cursor.editing = false;
            }
        }
        Keys.onEscapePressed: (keyEvent) => {
            keyEvent.accepted = true;
            if (input.text !== "")
                input.text = "";
            else
                input.focus = false;
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            text: field.placeholder
            color: Theme.textMuted
            font: Theme.body
        }

    }

    IconButton {
        id: clearButton

        anchors.right: parent.right
        anchors.rightMargin: Theme.space(1)
        anchors.verticalCenter: parent.verticalCenter
        visible: input.text !== ""
        cursorTarget: field
        glyph: "󰅖"
        onActivated: field.clear()
    }

    MouseArea {
        anchors.fill: parent
        anchors.rightMargin: clearButton.visible ? clearButton.width + Theme.space(2) : 0
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
        onContainsMouseChanged: {
            if (containsMouse) {
                Cursor.item = field;
            }
        }
        onClicked: input.forceActiveFocus()
    }

}
