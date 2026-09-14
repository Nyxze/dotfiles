import ".."
import "../widgets"
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Live notifications, stacked under the bar. Not built on Panel: toasts carry
// no frame of their own and must never take keyboard focus.
PanelWindow {
    id: toasts

    // Shifted aside while the sidebar is open so the two do not stack up.
    property int sideOffset: 0

    visible: NotificationService.popups.length > 0

    anchors {
        top: true
        right: true
    }

    margins {
        top: 10
        right: 10 + sideOffset
    }

    implicitWidth: 380
    implicitHeight: Math.max(1, stack.implicitHeight)
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "endfield-toasts"
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0

    ColumnLayout {
        id: stack

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 8

        Repeater {
            model: NotificationService.popups

            NotificationEntry {
                id: toast

                required property var modelData

                notification: modelData
                Layout.fillWidth: true

                onDismissed: NotificationService.dismiss(modelData)

                // A zero or negative expireTimeout means "until dismissed";
                // critical notifications are held regardless.
                readonly property int dwell: {
                    if (modelData.urgency === NotificationUrgency.Critical)
                        return 0;
                    if (modelData.expireTimeout > 0)
                        return modelData.expireTimeout;
                    return modelData.urgency === NotificationUrgency.Low ? 4000 : 7000;
                }

                Timer {
                    interval: toast.dwell
                    running: toast.dwell > 0 && !hover.hovered
                    onTriggered: NotificationService.dropPopup(toast.modelData)
                }

                HoverHandler {
                    id: hover
                }
            }
        }
    }
}
