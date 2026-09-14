import ".."
import "../components"
import QtQuick
import QtQuick.Layouts

Card {
    id: notifications

    readonly property var entries: NotificationService.history.values

    title: "Notifications"

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: notifications.entries.length === 0
                ? "Nothing waiting"
                : notifications.entries.length + (notifications.entries.length === 1 ? " notification" : " notifications")
            color: Theme.mediumGray
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        IconButton {
            glyph: NotificationService.doNotDisturb ? "󰂛" : "󰂚"
            onActivated: NotificationService.doNotDisturb = !NotificationService.doNotDisturb
        }

        IconButton {
            glyph: "󰩹"
            onActivated: NotificationService.clearHistory()
        }
    }

    Repeater {
        model: notifications.entries

        NotificationEntry {
            required property var modelData

            notification: modelData
            Layout.fillWidth: true
            onDismissed: NotificationService.dismiss(modelData)
        }
    }
}
