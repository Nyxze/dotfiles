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

    // Height of the visible frame, or -1 to fill the window. A panel anchored
    // top to bottom gets the real available height from the compositor, which
    // is the only way to know what the bar's exclusive zone left over; the
    // input mask then keeps the unused strip click-through.
    property int contentHeight: -1

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

    // Overridable: a panel with its own navigation backs out one level before
    // it closes. Not named `escape`: QML reserves it, like open/close/show/hide.
    function dismiss() {
        closePanel();
    }

    mask: Region {
        item: frame
    }

    Rectangle {
        id: frame

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: panel.contentHeight < 0
            ? panel.height
            : Math.min(panel.contentHeight, panel.height)

        radius: Theme.radius
        color: Theme.base
        border.width: 1
        border.color: Theme.overlay

        focus: true
        Keys.onEscapePressed: panel.dismiss()

        Item {
            id: body
            anchors.fill: parent
            anchors.margins: Theme.padding
        }
    }
}
