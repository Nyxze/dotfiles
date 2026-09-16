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

    implicitHeight: Theme.space(9)
    color: Theme.bgDeep
    border.width: input.activeFocus ? Theme.borderEmphasis : Theme.border
    border.color: input.activeFocus ? Theme.accent : Theme.line

    TextInput {
        id: input

        anchors.left: parent.left
        anchors.right: submit.left
        anchors.leftMargin: Theme.space(3)
        anchors.rightMargin: Theme.space(2)
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        echoMode: TextInput.Password
        color: Theme.textPrimary
        selectionColor: Theme.accent
        selectedTextColor: Theme.onAccent
        font: Theme.body

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
            color: Theme.textMuted
            font: Theme.body
        }
    }

    IconButton {
        id: submit

        anchors.right: parent.right
        anchors.rightMargin: Theme.space(1)
        anchors.verticalCenter: parent.verticalCenter
        glyph: "󰌑"
        onActivated: field.accepted(input.text)
    }
}
