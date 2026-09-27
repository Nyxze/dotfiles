import "backdrop"
import "components"
import QtQuick
import QtQuick.Window

// The greeter: a neutral ground, the clock, the login plate and the session
// list. The composition deliberately echoes hyprlock — same clock, same well,
// same position — so the lock screen and the login screen read as one surface.
Item {
    id: root

    width: Screen.width
    height: Screen.height

    property int userIndex: userModel.lastIndex
    property int sessionIndex: sessionModel.lastIndex

    // Set while PAM is deciding. The field goes read-only rather than
    // disappearing: a greeter that blanks on submit reads as a crash.
    property bool busy: false

    property string message: ""
    property color messageColor: Theme.danger

    // The account to authenticate, as opposed to the name shown. A model role
    // is only reachable from inside a delegate, so the visible user writes it
    // here rather than the root reading it back out of the model.
    property string userName: ""

    function login() {
        if (root.busy || root.userName === "")
            return;
        root.busy = true;
        root.message = "";
        sddm.login(root.userName, field.password, root.sessionIndex);
    }

    function stepSession(delta) {
        const count = sessionModel.rowCount();
        if (count < 2)
            return;
        root.sessionIndex = (root.sessionIndex + delta + count) % count;
    }

    Connections {
        target: sddm

        function onLoginSucceeded() {
            root.messageColor = Theme.success;
            root.message = "Welcome";
        }

        function onLoginFailed() {
            root.busy = false;
            root.messageColor = Theme.danger;
            root.message = "Authentication failed";
            field.failed = true;
            field.clear();
            field.focusInput();
        }

        function onInformationMessage(message) {
            root.messageColor = Theme.info;
            root.message = message;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bgDeep
    }

    Texture {
        anchors.fill: parent
        kind: "hatch"
        opacity: 0.3
    }

    Orbit {
        anchors.fill: parent
        models: Qt.resolvedUrl("backdrop/clouds/")
        fallback: Qt.resolvedUrl("ground.png")
    }

    Column {
        anchors.centerIn: parent
        width: Theme.space(130)
        spacing: Theme.space(10)

        Column {
            width: parent.width
            spacing: Theme.space(1)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(clock.now, "h:mm AP")
                color: Theme.textPrimary
                font: Theme.clock
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(clock.now, "dddd d MMMM")
                color: Theme.textMuted
                font: Theme.label
            }
        }

        Item {
            width: parent.width
            height: plate.height

            ChamferedRect {
                id: plate

                width: parent.width
                height: body.height + Theme.space(12)
                topLeft: true
                bottomRight: true
                chamfer: Theme.space(2)
                color: Theme.bgPanel
                borderColor: Theme.line
                borderWidth: Theme.border
            }

            Column {
                id: body

                anchors.horizontalCenter: plate.horizontalCenter
                y: Theme.space(6)
                width: plate.width - Theme.space(12)
                spacing: Theme.space(5)

                Column {
                    width: parent.width
                    spacing: Theme.space(1)

                    Repeater {
                        model: userModel

                        Text {
                            required property int index
                            required property string name
                            required property string realName

                            visible: index === root.userIndex
                            text: realName === "" ? name : realName
                            color: Theme.textPrimary
                            font: Theme.h2

                            onVisibleChanged: if (visible)
                                root.userName = name
                            Component.onCompleted: if (visible)
                                root.userName = name
                        }
                    }

                    Text {
                        text: sddm.hostName
                        color: Theme.textMuted
                        font: Theme.micro
                    }
                }

                LoginWell {
                    id: field

                    width: parent.width
                    busy: root.busy
                    capsLock: keyboard.capsLock
                    onAccepted: root.login()
                    onStepped: delta => root.stepSession(delta)
                }

                // Reserved whether or not there is anything to say, so the
                // plate does not resize under the cursor on a failed attempt.
                Text {
                    width: parent.width
                    height: Theme.space(4)
                    text: root.message
                    color: root.messageColor
                    elide: Text.ElideRight
                    font: Theme.bodySmall
                }
            }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.space(8)
        visible: keyboard.enabled && keyboard.layouts.length > 0
        text: visible ? keyboard.layouts[keyboard.currentLayout].shortName : ""
        color: Theme.textMuted
        font: Theme.micro
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.space(8)
        spacing: Theme.space(2)

        IconButton {
            glyph: "󰒲"
            visible: sddm.canSuspend
            onActivated: sddm.suspend()
        }

        IconButton {
            glyph: "󰜉"
            visible: sddm.canReboot
            onActivated: sddm.reboot()
        }

        IconButton {
            glyph: "󰐥"
            visible: sddm.canPowerOff
            onActivated: sddm.powerOff()
        }
    }

    SessionMenu {
        anchors.fill: parent
        model: sessionModel
        index: root.sessionIndex
        onPicked: picked => {
            root.sessionIndex = picked;
            field.focusInput();
        }
    }

    QtObject {
        id: clock

        property date now: new Date()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock.now = new Date()
    }

    Component.onCompleted: field.focusInput()
}
