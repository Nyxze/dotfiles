import ".."
import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

// Clock on the left, battery on the right. Both halves are shortcuts into the
// detail pages that would otherwise need a tile of their own.
RowLayout {
    id: header

    readonly property var locale: Qt.locale("fr_FR")
    readonly property var battery: UPower.displayDevice
    readonly property bool charging: battery
        && (battery.state === UPowerDeviceState.Charging
            || battery.state === UPowerDeviceState.FullyCharged)

    signal pageRequested(string page)

    function humanise(seconds) {
        if (!seconds || seconds <= 0)
            return "";
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.round((seconds % 3600) / 60);
        return hours > 0 ? `${hours} h ${minutes} min` : `${minutes} min`;
    }

    spacing: Theme.space(3)

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Both halves wrap their column in an Item: a MouseArea placed straight
    // into a Layout would be sized by it instead of covering its siblings.
    Item {
        id: clockStop

        readonly property bool navigable: true
        readonly property bool hasCursor: Cursor.item === clockStop

        function navActivate() {
            header.pageRequested("calendar");
        }

        Layout.fillWidth: true
        Layout.alignment: Qt.AlignBottom
        implicitHeight: clockBlock.implicitHeight

        ColumnLayout {
            id: clockBlock

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 0

            Text {
                text: clock.date.toLocaleString(header.locale, "HH:mm")
                color: Theme.textPrimary
                font: Theme.numeric
            }

            Text {
                text: clock.date.toLocaleString(header.locale, "dddd d MMMM")
                color: clockStop.hasCursor ? Theme.accent : Theme.textMuted
                font: Theme.label
            }
        }

        MouseArea {
            id: clockMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onContainsMouseChanged: if (containsMouse) Cursor.item = clockStop
            onClicked: header.pageRequested("calendar")
        }
    }

    Item {
        id: batteryStop

        readonly property bool navigable: true
        readonly property bool hasCursor: Cursor.item === batteryStop

        function navActivate() {
            header.pageRequested("power");
        }

        Layout.alignment: Qt.AlignBottom
        implicitWidth: batteryBlock.implicitWidth
        implicitHeight: batteryBlock.implicitHeight

        ColumnLayout {
            id: batteryBlock

            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 0

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: Theme.space(2)

                Text {
                    text: header.charging ? "󰂄" : "󰁹"
                    color: {
                        if (header.charging)
                            return Theme.success;
                        if (!header.battery || header.battery.percentage > 0.15)
                            return batteryStop.hasCursor ? Theme.accent : Theme.textSecondary;
                        return Theme.danger;
                    }
                    font: Theme.glyphSmall
                }

                Text {
                    text: header.battery ? Math.round(header.battery.percentage * 100) + "%" : "--"
                    color: batteryStop.hasCursor ? Theme.accent : Theme.textPrimary
                    font: Theme.h3
                }
            }

            Text {
                readonly property string remaining: header.battery
                    ? header.humanise(header.charging ? header.battery.timeToFull : header.battery.timeToEmpty)
                    : ""

                Layout.alignment: Qt.AlignRight
                text: remaining === ""
                    ? (header.charging ? "On AC" : "")
                    : (header.charging ? remaining + " to full" : remaining + " left")
                color: Theme.textMuted
                font: Theme.micro
            }
        }

        MouseArea {
            id: batteryMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onContainsMouseChanged: if (containsMouse) Cursor.item = batteryStop
            onClicked: header.pageRequested("power")
        }
    }
}
