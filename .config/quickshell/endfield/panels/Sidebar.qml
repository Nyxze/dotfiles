import ".."
import "../components"
import "../pages"
import "../widgets"
import QtQuick
import QtQuick.Layouts

// Quick settings: a fixed head that never scrolls — clock, tiles, levels — over
// a content region that swaps between detail pages. Notifications are the
// resting page, so closing a detail view lands back on the feed.
Panel {
    id: sidebar

    readonly property var pageTitles: ({
        notifications: "Notifications",
        output: "Output",
        input: "Input",
        bluetooth: "Bluetooth",
        calendar: "Calendar",
        power: "Power"
    })

    property string page: "notifications"

    // Clicking the chevron that is already open goes back, so a tile is both
    // the way in and the way out.
    function show(name) {
        page = page === name ? "notifications" : name;
    }

    anchors {
        top: true
        right: true
        bottom: true
    }

    margins {
        top: 10
        right: 10
        bottom: 10
    }

    surfaceName: "endfield-sidebar"
    implicitWidth: 380

    // Grow with the content instead of always spanning the screen: an empty
    // notification feed left most of a full-height panel as dead space.
    contentHeight: stack.implicitHeight + 2 * Theme.padding

    onShownChanged: {
        if (!shown)
            page = "notifications";
    }

    ColumnLayout {
        id: stack

        anchors.fill: parent
        spacing: 16

        SidebarHeader {
            Layout.fillWidth: true
            onPageRequested: name => sidebar.show(name)
        }

        QuickTiles {
            Layout.fillWidth: true
            onPageRequested: name => sidebar.show(name)
        }

        VolumeControls {
            Layout.fillWidth: true
            onPageRequested: name => sidebar.show(name)
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 2
            implicitHeight: 1
            color: Qt.alpha(Theme.overlay, 0.4)
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            IconButton {
                visible: sidebar.page !== "notifications"
                glyph: "‹"
                onActivated: sidebar.page = "notifications"
            }

            Text {
                Layout.fillWidth: true
                text: sidebar.pageTitles[sidebar.page]
                color: Theme.mediumGray
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.capitalization: Font.AllUppercase
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
            }

            IconButton {
                visible: sidebar.page === "notifications"
                    && NotificationService.history.values.length > 0
                glyph: "󰩹"
                onActivated: NotificationService.clearHistory()
            }
        }

        Flickable {
            id: scroller

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: contentHeight
            contentHeight: content.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            Loader {
                id: content

                width: scroller.width
                height: implicitHeight

                sourceComponent: {
                    switch (sidebar.page) {
                    case "output":
                        return outputPage;
                    case "input":
                        return inputPage;
                    case "bluetooth":
                        return bluetoothPage;
                    case "calendar":
                        return calendarPage;
                    case "power":
                        return powerPage;
                    default:
                        return notificationsPage;
                    }
                }
            }
        }
    }

    Component {
        id: notificationsPage

        NotificationsPage {}
    }

    Component {
        id: outputPage

        OutputPage {}
    }

    Component {
        id: inputPage

        InputPage {}
    }

    Component {
        id: bluetoothPage

        BluetoothPage {}
    }

    Component {
        id: calendarPage

        CalendarPage {}
    }

    Component {
        id: powerPage

        PowerPage {}
    }
}
