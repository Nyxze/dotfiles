import ".."
import "../widgets"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page

    // trackedNotifications is insertion-ordered; a feed reads newest first.
    readonly property var entries: NotificationService.history.values.slice().reverse()

    spacing: Theme.space(2)

    Text {
        Layout.fillWidth: true
        Layout.topMargin: Theme.space(1)
        visible: page.entries.length === 0
        text: "Nothing waiting"
        color: Theme.line
        font: Theme.body
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
