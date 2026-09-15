import ".."
import QtQuick

// Inline secret entry. Enter submits, Escape cancels — and the cancel must eat
// the key, or Panel's own Escape handler closes the whole panel behind it.
Rectangle {
    id: field

    property string placeholder: "Password"

    signal accepted(string value)
    signal cancelled

    function clear() {
        input.text = "";
    }

    function focusInput() {
        input.forceActiveFocus();
    }

    implicitHeight: 34
    radius: 7
    color: Theme.base
    border.width: 1
    border.color: input.activeFocus ? Theme.brightYellow : Theme.overlay

    TextInput {
        id: input

        anchors.left: parent.left
        anchors.right: submit.left
        anchors.leftMargin: 10
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        echoMode: TextInput.Password
        color: Theme.text
        selectionColor: Theme.oliveGreen
        selectedTextColor: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 13

        onAccepted: field.accepted(text)

        // The panel's key handler stands down while this has focus, or typing
        // "j" into a passphrase would walk down a row instead.
        onActiveFocusChanged: Cursor.editing = activeFocus
        Component.onDestruction: if (activeFocus)
            Cursor.editing = false

        Keys.onEscapePressed: keyEvent => {
            keyEvent.accepted = true;
            field.cancelled();
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            text: field.placeholder
            color: Theme.overlay
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }
    }

    IconButton {
        id: submit

        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        glyph: "󰌑"
        onActivated: field.accepted(input.text)
    }
}
