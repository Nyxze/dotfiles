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

    spacing: 10

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Both halves wrap their column in an Item: a MouseArea placed straight
    // into a Layout would be sized by it instead of covering its siblings.
    Item {
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
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 30
                font.weight: Font.Light
            }

            Text {
                text: clock.date.toLocaleString(header.locale, "dddd d MMMM")
                color: clockMouse.containsMouse ? Theme.brightYellow : Theme.mediumGray
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.capitalization: Font.Capitalize
            }
        }

        MouseArea {
            id: clockMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: header.pageRequested("calendar")
        }
    }

    Item {
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
                spacing: 6

                Text {
                    text: header.charging ? "󰂄" : "󰁹"
                    color: {
                        if (header.charging)
                            return Theme.success;
                        if (!header.battery || header.battery.percentage > 0.15)
                            return batteryMouse.containsMouse ? Theme.brightYellow : Theme.lightGray;
                        return Theme.critical;
                    }
                    font.family: Theme.monoFamily
                    font.pixelSize: 17
                }

                Text {
                    text: header.battery ? Math.round(header.battery.percentage * 100) + "%" : "--"
                    color: batteryMouse.containsMouse ? Theme.brightYellow : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 17
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
                color: Theme.mediumGray
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
        }

        MouseArea {
            id: batteryMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: header.pageRequested("power")
        }
    }
}
