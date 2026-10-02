import ".."
import Quickshell
import QtQuick

// X11 PanelWindow does not expose wlroots layer-shell properties. i3 places
// this normal panel; Xfce remains usable when the shell is not running.
PanelWindow {
    id: panel

    default property alias content: body.data

    property string surfaceName: "endfield-panel"
    property bool shown: false
    property var resolvedScreen: null
    property Item focusTarget: frame
    property int contentHeight: -1

    visible: shown
    screen: resolvedScreen
    color: "transparent"

    function openPanel() {
        FocusedScreen.resolve(function (screen) {
            if (screen)
                panel.resolvedScreen = screen;
            panel.shown = true;
        });
    }

    function closePanel() { shown = false; }
    function toggle() { shown ? closePanel() : openPanel(); }
    function dismiss() { closePanel(); }

    ChamferedRect {
        id: frame
        anchors.fill: parent
        topLeft: true
        bottomRight: true
        color: Theme.bgPanel
        borderColor: Theme.line
        borderWidth: Theme.border
        focus: true
        Keys.onEscapePressed: panel.dismiss()

        Texture {
            anchors.fill: parent
            kind: "grid"
        }

        Item {
            id: body
            anchors.fill: parent
            anchors.margins: Theme.padding
        }
    }
}
