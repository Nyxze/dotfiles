import ".."
import Quickshell
import Quickshell.Io
import QtQuick

// A normal X11 window stays out of i3's dock area. i3 floats Endfield windows
// by title, so opening a sidebar never reserves most of the desktop.
FloatingWindow {
    id: panel

    default property alias content: body.data

    property string surfaceName: "endfield-panel"
    property bool shown: false
    property var resolvedScreen: null
    property Item focusTarget: frame
    property int contentHeight: -1
    property int panelWidth: 380
    property int panelHeight: 0
    readonly property int topReserved: Theme.space(8) // Native Xfce top panel.

    property bool panelTop: false
    property bool panelRight: false
    property bool panelBottom: false
    property bool panelLeft: false
    property int panelTopMargin: 0
    property int panelRightMargin: 0
    property int panelBottomMargin: 0
    property int panelLeftMargin: 0
    property int exclusionMode: 0

    readonly property var targetScreen: resolvedScreen || (Quickshell.screens.length ? Quickshell.screens[0] : null)
    readonly property int availableWidth: targetScreen ? Math.max(1, targetScreen.width - panelLeftMargin - panelRightMargin) : panelWidth
    readonly property int availableHeight: targetScreen ? Math.max(1, targetScreen.height - panelTopMargin - panelBottomMargin) : panelHeight

    title: surfaceName
    visible: shown
    screen: resolvedScreen
    color: "transparent"
    implicitWidth: Math.min(panelLeft && panelRight ? availableWidth : panelWidth, availableWidth)
    implicitHeight: Math.min(contentHeight >= 0 ? contentHeight : panelHeight, availableHeight)
    readonly property int desiredX: !targetScreen ? 0 : panelLeft ? targetScreen.x + panelLeftMargin
        : panelRight ? targetScreen.x + targetScreen.width - panelRightMargin - implicitWidth
        : targetScreen.x + (targetScreen.width - implicitWidth) / 2
    readonly property int desiredY: !targetScreen ? 0 : panelTop ? targetScreen.y + panelTopMargin
        : panelBottom ? targetScreen.y + targetScreen.height - panelBottomMargin - implicitHeight
        : targetScreen.y + (targetScreen.height - implicitHeight) / 2

    // i3 owns the size of a floating window after mapping. Follow later page
    // reflows explicitly, including network scans and notification changes.
    onImplicitWidthChanged: if (shown) positionTimer.restart()
    onImplicitHeightChanged: if (shown) positionTimer.restart()
    onPanelTopMarginChanged: if (shown) positionTimer.restart()

    Timer {
        id: positionTimer
        interval: 100
        onTriggered: if (panel.shown) positioner.running = true
    }

    Process {
        id: positioner
        command: ["i3-msg", "[title=\"^" + panel.surfaceName + "$\"] resize set width "
            + panel.implicitWidth + " px height " + panel.implicitHeight
            + " px, move position " + panel.desiredX + " px " + panel.desiredY + " px"]
    }

    function openPanel() {
        FocusedScreen.resolve(function (screen) {
            if (screen)
                panel.resolvedScreen = screen;
            panel.shown = true;
            positionTimer.restart();
            Qt.callLater(function () {
                if (panel.shown && panel.focusTarget)
                    panel.focusTarget.forceActiveFocus();
            });
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
