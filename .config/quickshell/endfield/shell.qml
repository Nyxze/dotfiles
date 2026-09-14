import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

ShellRoot {
    id: root

    property bool calendarVisible: false

    IpcHandler {
        target: "calendar"

        function toggle(): void {
            root.calendarVisible = !root.calendarVisible;
        }

        function show(): void {
            root.calendarVisible = true;
        }

        function hide(): void {
            root.calendarVisible = false;
        }
    }

    PanelWindow {
        id: win

        visible: root.calendarVisible

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
        exclusionMode: ExclusionMode.Ignore

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
