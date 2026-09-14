import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

ShellRoot {
    id: root

    property bool calendarVisible: false
    property var targetScreen: null

    // Quickshell's Hyprland.focusedMonitor is never seeded at startup — it only
    // reflects focus changes that happen afterwards — so ask Hyprland directly
    // each time instead. One subprocess per toggle is not worth optimising.
    Process {
        id: focusQuery
        command: ["hyprctl", "monitors", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                let focusedName = "";
                try {
                    const monitors = JSON.parse(this.text);
                    for (const monitor of monitors) {
                        if (monitor.focused) {
                            focusedName = monitor.name;
                            break;
                        }
                    }
                } catch (e) {
                    console.warn("calendar: could not read hyprctl monitors:", e);
                }
                root.showOn(focusedName);
            }
        }
    }

    function showOn(screenName) {
        for (const screen of Quickshell.screens) {
            if (screen.name === screenName) {
                targetScreen = screen;
                break;
            }
        }
        calendarVisible = true;
    }

    IpcHandler {
        target: "calendar"

        function toggle(): void {
            if (root.calendarVisible)
                root.calendarVisible = false;
            else
                focusQuery.running = true;
        }

        function show(): void {
            focusQuery.running = true;
        }

        function hide(): void {
            root.calendarVisible = false;
        }
    }

    PanelWindow {
        id: win

        visible: root.calendarVisible
        screen: root.targetScreen

        anchors {
            top: true
            right: true
        }

        margins {
            top: 10
            right: 10
        }

        implicitWidth: 340
        implicitHeight: 400
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "endfield-calendar"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        // Sit below the bar without reserving any space of its own: Normal
        // respects other surfaces' zones, and a zero zone claims none.
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: Theme.base
            border.width: 1
            border.color: Theme.overlay

            focus: true
            Keys.onEscapePressed: root.calendarVisible = false

            Calendar {
                anchors.fill: parent
                anchors.margins: Theme.padding
            }
        }
    }
}
