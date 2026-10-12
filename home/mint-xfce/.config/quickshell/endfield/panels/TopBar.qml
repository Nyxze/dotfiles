pragma ComponentBehavior: Bound

import ".."
import Quickshell
import Quickshell.I3
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import QtQuick

// The X11/i3 counterpart of the Hyprland top bar.  Each PanelWindow is
// attached to its QScreen, so monitor changes are handled by Quickshell rather
// than by an output-specific launcher or a positioned overlay.
Scope {
    id: root

    signal sidebarPageRequested(string page)
    signal sidebarToggleRequested()

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: bar

            required property var modelData

            readonly property bool laptop: modelData.name === "eDP"
            readonly property var workspaceNames: laptop ? ["0"] : ["1", "2", "3", "4", "5"]
            readonly property var battery: UPower.displayDevice
            readonly property bool charging: battery && (battery.state === UPowerDeviceState.Charging
                || battery.state === UPowerDeviceState.FullyCharged)
            // The bar stays compact, but its information needs to remain legible
            // at laptop distance without changing the shared Hyprland theme.
            readonly property font workspaceFont: Qt.font({
                family: Theme.fontFamily,
                pixelSize: 15,
                weight: 400
            })
            readonly property font statusFont: Qt.font({
                family: Theme.fontFamily,
                pixelSize: 13,
                weight: 400
            })
            readonly property font statusGlyphFont: Qt.font({
                family: Theme.monoFamily,
                pixelSize: 18
            })

            screen: modelData
            implicitHeight: 32
            // This mirrors the Hyprland Waybar: the wallpaper is the bar's
            // ground, so changing wallpapers never leaves a mismatched strip.
            color: "transparent"
            focusable: false
            aboveWindows: true
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: implicitHeight

            anchors {
                top: true
                left: true
                right: true
            }

            function workspace(name) {
                return I3.workspaces.values.find(candidate => candidate.name === name) || null;
            }

            function activateWorkspace(name) {
                I3.dispatch("workspace number " + name);
            }

            component StatusButton: Item {
                id: statusButton

                property string glyph: ""
                property string label: ""
                property color glyphColor: Theme.textSecondary
                property color labelColor: Theme.textSecondary
                property string tooltip: ""
                signal leftClicked()
                signal rightClicked()

                implicitWidth: content.implicitWidth + Theme.space(3)
                implicitHeight: bar.implicitHeight

                Row {
                    id: content

                    anchors.centerIn: parent
                    spacing: Theme.space(1)

                    Text {
                        visible: statusButton.glyph !== ""
                        text: statusButton.glyph
                        color: statusButton.glyphColor
                        font: bar.statusGlyphFont
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        visible: statusButton.label !== ""
                        text: statusButton.label
                        color: statusButton.labelColor
                        font: bar.statusFont
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton)
                            statusButton.rightClicked();
                        else
                            statusButton.leftClicked();
                    }
                }
            }

            Row {
                id: workspaces

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Repeater {
                    model: bar.workspaceNames

                    delegate: Item {
                        id: workspaceButton

                        required property string modelData
                        readonly property var workspace: bar.workspace(modelData)
                        readonly property bool focused: workspace && workspace.focused
                        readonly property bool urgent: workspace && workspace.urgent

                        width: Theme.space(9)
                        height: bar.implicitHeight

                        Rectangle {
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Theme.space(6)
                            height: 3
                            color: workspaceButton.urgent ? Theme.accentSoft : Theme.accent
                            visible: workspaceButton.focused || workspaceButton.urgent
                        }

                        Text {
                            anchors.centerIn: parent
                            text: workspaceButton.modelData
                            color: workspaceButton.focused ? Theme.textPrimary : Theme.textMuted
                            font: bar.workspaceFont
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bar.activateWorkspace(workspaceButton.modelData)
                        }
                    }
                }
            }

            Row {
                id: status

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                StatusButton {
                    glyph: NetworkService.glyph
                    label: NetworkService.status
                    onLeftClicked: root.sidebarPageRequested("network")
                }

                StatusButton {
                    glyph: AudioService.mutedOf(AudioService.sink) ? "󰝟" : "󰕾"
                    label: AudioService.sink
                        ? (AudioService.mutedOf(AudioService.sink) ? "muted"
                            : Math.round(AudioService.volumeOf(AudioService.sink) * 100) + "%")
                        : "--"
                    labelColor: AudioService.mutedOf(AudioService.sink) ? Theme.textMuted : Theme.textSecondary
                    onLeftClicked: root.sidebarPageRequested("output")
                    onRightClicked: pavucontrol.running = true
                }

                StatusButton {
                    glyph: bar.charging ? "󰂄" : "󰁹"
                    label: bar.battery ? Math.round(bar.battery.percentage * 100) + "%" : "--"
                    glyphColor: bar.charging ? Theme.accentSoft : Theme.textSecondary
                    onLeftClicked: root.sidebarPageRequested("power")
                }

                Item {
                    id: tray

                    visible: SystemTray.items.values.length > 0
                    implicitWidth: trayIcons.implicitWidth + Theme.space(2)
                    implicitHeight: bar.implicitHeight

                    Row {
                        id: trayIcons

                        anchors.centerIn: parent
                        spacing: Theme.space(1)

                        Repeater {
                            model: SystemTray.items

                            delegate: Item {
                                id: trayEntry

                                required property var modelData

                                width: Theme.space(5)
                                height: Theme.space(5)

                                Image {
                                    anchors.fill: parent
                                    source: trayEntry.modelData.icon
                                    sourceSize.width: width
                                    sourceSize.height: height
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: mouse => {
                                        const item = trayEntry.modelData;
                                        if (mouse.button === Qt.LeftButton) {
                                            if (item.onlyMenu)
                                                openMenu();
                                            else
                                                item.activate();
                                        } else if (mouse.button === Qt.MiddleButton) {
                                            item.secondaryActivate();
                                        } else {
                                            openMenu();
                                        }
                                    }

                                    onWheel: wheel => trayEntry.modelData.scroll(wheel.angleDelta.y, false)

                                    function openMenu() {
                                        const item = trayEntry.modelData;
                                        if (!item.hasMenu)
                                            return;
                                        const point = trayEntry.mapToItem(null, 0, trayEntry.height + Theme.space(1));
                                        item.display(bar, point.x, point.y);
                                    }
                                }
                            }
                        }
                    }
                }

                StatusButton {
                    glyph: "󰒓"
                    glyphColor: Theme.textMuted
                    onLeftClicked: root.sidebarToggleRequested()
                    onRightClicked: DisplayService.setMode()
                }

                StatusButton {
                    glyph: "󰃭"
                    label: clock.date.toLocaleString(Qt.locale("fr_FR"), "ddd dd MMM  HH:mm")
                    glyphColor: Theme.accentSoft
                    labelColor: Theme.accentSoft
                    onLeftClicked: root.sidebarPageRequested("calendar")
                }

                StatusButton {
                    glyph: "󰐥"
                    glyphColor: Theme.textMuted
                    onLeftClicked: root.sidebarPageRequested("power")
                }
            }

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            Process {
                id: pavucontrol
                command: ["pavucontrol"]
            }
        }
    }
}
