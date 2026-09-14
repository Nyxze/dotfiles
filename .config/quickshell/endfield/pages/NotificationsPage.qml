import ".."
import "../widgets"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page

    // trackedNotifications is insertion-ordered; a feed reads newest first.
    readonly property var entries: NotificationService.history.values.slice().reverse()

    spacing: 8

    Text {
        Layout.fillWidth: true
        Layout.topMargin: 4
        visible: page.entries.length === 0
        text: "Nothing waiting"
        color: Theme.overlay
        font.family: Theme.fontFamily
        font.pixelSize: 12
    }

    Repeater {
        model: page.entries

        NotificationEntry {
            required property var modelData

            Layout.fillWidth: true
            notification: modelData
            onDismissed: NotificationService.dismiss(modelData)
        }
    }
}
