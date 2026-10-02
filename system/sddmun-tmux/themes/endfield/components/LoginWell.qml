import ".."
import QtQuick

// The password well of a login surface — the lock screen and the greeter.
// Unlike the inline PasswordField it has no submit button: it owns the
// keyboard for the whole screen, so the arrow keys, dead input in a
// single-line field, are handed back out to whatever the surface puts behind
// them.
//
// It goes read-only rather than disappearing while the password is checked: a
// field that blanks on submit reads as a crash.
Rectangle {
    id: field

    property string placeholder: "Password"
    property bool failed: false
    property bool busy: false

    // Fed by the surface: neither SDDM's keyboard model nor the compositor's
    // is reachable from here, and they are not the same object.
    property bool capsLock: false

    readonly property alias password: input.text

    signal accepted(string value)
    signal stepped(int delta)

    function clear() {
        input.text = "";
    }

    function focusInput() {
        input.forceActiveFocus();
    }

    implicitHeight: Theme.space(11)
    color: Theme.bgDeep
    border.width: input.activeFocus ? Theme.borderEmphasis : Theme.border
    border.color: {
        if (field.failed)
            return Theme.danger;
        return input.activeFocus ? Theme.accent : Theme.line;
    }

    TextInput {
        id: input

        anchors.left: parent.left
        anchors.right: caps.left
        anchors.leftMargin: Theme.space(4)
        anchors.rightMargin: Theme.space(2)
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        // The surface has exactly one thing to type into, so the field claims
        // the window's focus rather than waiting to be given it: marked here,
        // it is refocused on its own every time the window is activated.
        focus: true
        echoMode: TextInput.Password
        readOnly: field.busy
        color: Theme.textPrimary
        selectionColor: Theme.accent
        selectedTextColor: Theme.onAccent
        font: Theme.body

        onAccepted: field.accepted(text)
        onTextChanged: field.failed = false

        Keys.onUpPressed: field.stepped(-1)
        Keys.onDownPressed: field.stepped(1)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            text: field.placeholder
            color: Theme.textMuted
            font: Theme.body
        }
    }

    Text {
        id: caps

        anchors.right: parent.right
        anchors.rightMargin: Theme.space(4)
        anchors.verticalCenter: parent.verticalCenter
        visible: field.capsLock
        text: "󰪛"
        color: Theme.accent
        font: Theme.glyphSmall
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onClicked: field.focusInput()
    }
}
