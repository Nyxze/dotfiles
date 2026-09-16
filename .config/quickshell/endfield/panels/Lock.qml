import ".."
import "../backdrop"
import "../components"
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import QtQuick

// The lock screen: the same composition as the SDDM greeter — same clock, same
// well, same backdrop — because they are one moment of the session seen from
// either side of it.
//
// The surface is instantiated per screen by the compositor, so everything the
// two copies must agree on (whether PAM is busy, what it last said) lives out
// here and is bound into them.
Scope {
    id: root

    readonly property bool locked: session.locked

    // The materials live beside the palette rather than in the shell, because
    // the greeter is copied from the same directory at install time. A path
    // through the config root would resolve into Quickshell's virtual qs:/
    // space and silently miss.
    readonly property string assets: "file://" + Quickshell.env("HOME") + "/.config/theme/"

    property bool busy: false
    property string message: ""
    property color messageColor: Theme.danger

    // PAM does not take the password with the request: it starts a
    // conversation and asks for it afterwards, so it waits here in between.
    property string pending: ""

    // Raised when an attempt fails, so every surface clears its own well.
    signal rejected

    function lock() {
        if (session.locked)
            return;
        root.message = "";
        clock.now = new Date();
        session.locked = true;
    }

    function authenticate(password) {
        if (root.busy || password === "")
            return;

        root.busy = true;
        root.message = "";
        root.pending = password;

        if (!pam.start()) {
            root.busy = false;
            root.messageColor = Theme.danger;
            root.message = "Authentication unavailable";
        }
    }

    PamContext {
        id: pam

        // The stock login stack, rather than a file of our own under
        // /etc/pam.d: one less root-owned thing to install for no gain.
        config: "login"

        onPamMessage: {
            if (pam.responseRequired) {
                pam.respond(root.pending);
                root.pending = "";
                return;
            }
            if (pam.message === "")
                return;
            root.messageColor = pam.messageIsError ? Theme.danger : Theme.info;
            root.message = pam.message;
        }

        onCompleted: result => {
            root.busy = false;
            root.pending = "";

            if (result === PamResult.Success) {
                root.message = "";
                session.locked = false;
                return;
            }

            root.messageColor = Theme.danger;
            root.message = result === PamResult.MaxTries ? "Too many attempts" : "Authentication failed";
            root.rejected();
        }

        onError: {
            root.busy = false;
            root.pending = "";
            root.messageColor = Theme.danger;
            root.message = "Authentication error";
            root.rejected();
        }
    }

    WlSessionLock {
        id: session

        WlSessionLockSurface {
            id: surface

            color: Theme.bgDeep

            Texture {
                anchors.fill: parent
                kind: "hatch"
                opacity: 0.3
            }

            Orbit {
                anchors.fill: parent
                models: root.assets + "clouds/"
                fallback: root.assets + "greeter.png"
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
                        text: Qt.formatTime(clock.now, "HH:mm")
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

                        Text {
                            text: Quickshell.env("USER")
                            color: Theme.textPrimary
                            font: Theme.h2
                        }

                        LoginWell {
                            id: well

                            width: parent.width
                            busy: root.busy
                            onAccepted: value => root.authenticate(value)

                            Component.onCompleted: focusInput()
                        }

                        // Reserved whether or not there is anything to say, so
                        // the plate does not resize under a failed attempt.
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

            Connections {
                target: root

                function onRejected() {
                    well.failed = true;
                    well.clear();
                    well.focusInput();
                }
            }
        }
    }

    QtObject {
        id: clock

        property date now: new Date()
    }

    Timer {
        interval: 1000
        running: session.locked
        repeat: true
        onTriggered: clock.now = new Date()
    }
}
