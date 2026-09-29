pragma ComponentBehavior: Bound

import ".."
import "../components"
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    function screenFor(name) {
        for (const screen of Quickshell.screens) {
            if (screen.name === name)
                return screen;
        }
        return null;
    }

    Variants {
        model: WindowGroupService.groups.map(group => group.key)

        delegate: PanelWindow {
            id: bar

            required property var modelData

            readonly property var group: WindowGroupService.groups.find(candidate => candidate.key === modelData) || null
            readonly property var monitor: group
                ? Hyprland.monitors.values.find(candidate => candidate.id === group.monitorId) || null
                : null
            readonly property var targetScreen: monitor ? root.screenFor(monitor.name) : null

            visible: group !== null
                && monitor !== null
                && targetScreen !== null
                && monitor.activeWorkspace !== null
                && monitor.activeWorkspace.name === group.workspaceName
            screen: targetScreen
            implicitWidth: group ? group.width : 1
            implicitHeight: Theme.space(6)
            color: "transparent"

            anchors {
                top: true
                left: true
            }

            margins {
                left: group && targetScreen ? group.x - targetScreen.x : 0
                top: group && targetScreen ? group.y - targetScreen.y - bar.implicitHeight : 0
            }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "endfield-groupbar"
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0

            RowLayout {
                id: tabs

                anchors.fill: parent
                spacing: 0

                Repeater {
                    model: bar.group ? bar.group.members : []

                    delegate: Item {
                        id: tab

                        required property var modelData

                        readonly property bool selected: modelData.address === bar.group.activeAddress
                        readonly property bool hasCursor: Cursor.item === tab
                        readonly property var desktopEntry: DesktopEntries.heuristicLookup(modelData.className)
                        readonly property string iconSource: desktopEntry && desktopEntry.icon
                            ? Quickshell.iconPath(desktopEntry.icon, true)
                            : ""
                        readonly property string appName: desktopEntry && desktopEntry.name
                            ? desktopEntry.name
                            : modelData.className

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumWidth: 0

                        ChamferedRect {
                            anchors.fill: parent
                            topLeft: tab.selected
                            topRight: tab.selected
                            color: tab.selected ? Theme.accent : Theme.bgPanel
                            borderWidth: tab.hasCursor ? Theme.borderEmphasis : Theme.border
                            borderColor: tab.hasCursor
                                ? (tab.selected ? Theme.onAccent : Theme.accent)
                                : (tab.selected ? Theme.accent : Theme.line)
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.space(2)
                            anchors.rightMargin: Theme.space(2)
                            spacing: Theme.space(2)

                            Image {
                                visible: tab.iconSource !== ""
                                source: tab.iconSource
                                Layout.preferredWidth: Theme.space(4)
                                Layout.preferredHeight: Theme.space(4)
                                fillMode: Image.PreserveAspectFit
                                sourceSize.width: 32
                                sourceSize.height: 32
                            }

                            Text {
                                Layout.fillWidth: true
                                text: tab.appName + "  ·  " + tab.modelData.title
                                color: tab.selected ? Theme.onAccent : Theme.textSecondary
                                font: Theme.bodySmall
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        HoverHandler {
                            cursorShape: Qt.PointingHandCursor
                            onHoveredChanged: if (hovered)
                                Cursor.item = tab
                        }

                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: Hyprland.dispatch("focuswindow address:" + tab.modelData.address)
                        }
                    }
                }

                WheelHandler {
                    onWheel: event => {
                        if (!bar.group)
                            return;
                        Hyprland.dispatch("focuswindow address:" + bar.group.activeAddress);
                        Hyprland.dispatch("changegroupactive " + (event.angleDelta.y > 0 ? "b" : "f"));
                        event.accepted = true;
                    }
                }
            }
        }
    }
}
