import ".."
import Quickshell
import Quickshell.Wayland
import QtQuick

// Shared chrome for every popup panel: layer-shell placement, the rounded
// frame, Escape to close, and opening on whichever screen has focus.
// Children are placed inside the padded frame.
PanelWindow {
    id: panel

    default property alias content: body.data

    // Shows up in `hyprctl layers`; give each panel its own so window rules and
    // debugging can tell them apart.
    property string surfaceName: "endfield-panel"

    property bool shown: false
    property var resolvedScreen: null

    visible: shown
    screen: resolvedScreen
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: surfaceName

    // Sit clear of the bar without reserving any space: Normal respects other
    // surfaces' exclusive zones, and a zero zone claims none.
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0

    // Named openPanel/closePanel rather than open/close: PanelWindow inherits
    // Window, which already defines those.
    function openPanel() {
        FocusedScreen.resolve(function (screen) {
            if (screen)
                panel.resolvedScreen = screen;
            panel.shown = true;
        });
    }

    function closePanel() {
        shown = false;
    }

    function toggle() {
        if (shown)
            closePanel();
        else
            openPanel();
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.base
        border.width: 1
        border.color: Theme.overlay

        focus: true
        Keys.onEscapePressed: panel.closePanel()

        Item {
            id: body
            anchors.fill: parent
            anchors.margins: Theme.padding
        }
    }
}
