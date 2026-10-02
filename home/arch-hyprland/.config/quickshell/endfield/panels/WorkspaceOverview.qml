pragma ComponentBehavior: Bound

import ".."
import "../components"
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Workspace switcher with live window thumbnails. SUPER+Tab advances while
// the modifier is held; releasing SUPER activates the highlighted workspace.
Panel {
    id: overview

    readonly property var workspaceNames: ["1", "2", "3", "4", "5", "Laptop"]
    property int selectedIndex: 0

    function workspaceAt(index) {
        const name = workspaceNames[index];
        return Hyprland.workspaces.values.find(workspace => workspace.name === name) || null;
    }

    function focusedIndex() {
        const focused = Hyprland.focusedWorkspace;
        if (!focused)
            return 0;
        const index = workspaceNames.indexOf(focused.name);
        return index < 0 ? 0 : index;
    }

    function step(direction) {
        if (!shown) {
            Hyprland.refreshWorkspaces();
            Hyprland.refreshToplevels();
            selectedIndex = focusedIndex();
            openPanel();
        }

        selectedIndex = (selectedIndex + direction + workspaceNames.length) % workspaceNames.length;
    }

    function accept() {
        if (!shown)
            return;
        const workspace = workspaceAt(selectedIndex);
        if (workspace)
            workspace.activate();
        else
            Hyprland.dispatch("hl.dsp.focus({ workspace = " + JSON.stringify("name:" + workspaceNames[selectedIndex]) + " })");
        closePanel();
    }

    function choose(index) {
        selectedIndex = index;
        accept();
    }

    function chooseWindow(toplevel) {
        if (!toplevel)
            return;
        if (toplevel.wayland)
            toplevel.wayland.activate();
        else if (toplevel.address)
            Hyprland.dispatch("hl.dsp.focus({ window = " + JSON.stringify("address:0x" + toplevel.address) + " })");
        closePanel();
    }

    function move(dx, dy) {
        const columns = 3;
        const row = Math.floor(selectedIndex / columns);
        const column = selectedIndex % columns;
        const nextRow = Math.max(0, Math.min(1, row + dy));
        const nextColumn = Math.max(0, Math.min(columns - 1, column + dx));
        selectedIndex = nextRow * columns + nextColumn;
    }

    function dismiss() {
        closePanel();
    }

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    margins {
        top: Theme.space(10)
        left: Theme.space(10)
        right: Theme.space(10)
        bottom: Theme.space(10)
    }

    surfaceName: "endfield-workspace-overview"
    contentHeight: Math.min(overview.height, 660)
    focusTarget: keyCatcher

    Item {
        id: keyCatcher

        anchors.fill: parent
        focus: true
        Keys.priority: Keys.BeforeItem

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Escape:
                overview.dismiss();
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
            case Qt.Key_Space:
                overview.accept();
                break;
            case Qt.Key_Left:
                overview.move(-1, 0);
                break;
            case Qt.Key_Right:
                overview.move(1, 0);
                break;
            case Qt.Key_Up:
                overview.move(0, -1);
                break;
            case Qt.Key_Down:
                overview.move(0, 1);
                break;
            default:
                return;
            }
            event.accepted = true;
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: Theme.space(4)

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space(3)

                Text {
                    text: "WORKSPACES"
                    color: Theme.textPrimary
                    font: Theme.h2
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Theme.border
                    color: Theme.line
                }

                Text {
                    text: "HOVER / CLICK / WHEEL  ·  RELEASE SUPER TO SELECT"
                    color: Theme.textMuted
                    font: Theme.micro
                }
            }

            GridLayout {
                id: workspaceGrid

                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 3
                rows: 2
                rowSpacing: Theme.space(3)
                columnSpacing: Theme.space(3)

                Repeater {
                    model: overview.workspaceNames

                    delegate: Item {
                        id: workspaceCard

                        required property int index
                        required property string modelData

                        readonly property var workspace: overview.workspaceAt(index)
                        readonly property int windowCount: workspace ? workspace.toplevels.values.length : 0
                        readonly property bool selected: index === overview.selectedIndex

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ChamferedRect {
                            anchors.fill: parent
                            topRight: true
                            bottomLeft: true
                            color: workspaceCard.selected ? Theme.bgRaised : Theme.bgDeep
                            borderColor: workspaceCard.selected ? Theme.accent : Theme.line
                            borderWidth: workspaceCard.selected ? Theme.borderEmphasis : Theme.border
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.space(3)
                            spacing: Theme.space(2)

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.space(2)

                                Rectangle {
                                    implicitWidth: Theme.space(6)
                                    implicitHeight: Theme.space(6)
                                    color: workspaceCard.selected ? Theme.accent : Theme.bgRaised
                                    border.width: Theme.border
                                    border.color: workspaceCard.selected ? Theme.accent : Theme.line

                                    Text {
                                        anchors.centerIn: parent
                                        text: workspaceCard.modelData === "Laptop" ? "L" : workspaceCard.modelData
                                        color: workspaceCard.selected ? Theme.onAccent : Theme.textSecondary
                                        font: Theme.label
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: workspaceCard.modelData === "Laptop"
                                        ? "LAPTOP"
                                        : "WORKSPACE " + workspaceCard.modelData
                                    color: workspaceCard.selected ? Theme.textPrimary : Theme.textSecondary
                                    font: Theme.label
                                }

                                Text {
                                    text: workspaceCard.windowCount + (workspaceCard.windowCount === 1 ? " WINDOW" : " WINDOWS")
                                    color: Theme.textMuted
                                    font: Theme.micro
                                }
                            }

                            Item {
                                id: previewArea

                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Text {
                                    anchors.centerIn: parent
                                    visible: workspaceCard.windowCount === 0
                                    text: "EMPTY"
                                    color: Theme.textMuted
                                    font: Theme.micro
                                }

                                Repeater {
                                    model: workspaceCard.workspace ? workspaceCard.workspace.toplevels : []

                                    delegate: Rectangle {
                                        id: windowPreview

                                        required property int index
                                        required property var modelData

                                        readonly property int columns: workspaceCard.windowCount <= 1
                                            ? 1
                                            : workspaceCard.windowCount <= 4 ? 2 : 3
                                        readonly property int rows: Math.ceil(workspaceCard.windowCount / columns)
                                        readonly property real gap: Theme.space(1)

                                        width: (previewArea.width - gap * (columns - 1)) / columns
                                        height: (previewArea.height - gap * (rows - 1)) / rows
                                        x: (index % columns) * (width + gap)
                                        y: Math.floor(index / columns) * (height + gap)
                                        color: Theme.bgPanel
                                        border.width: Theme.border
                                        border.color: windowHover.hovered ? Theme.accentSoft : Theme.line
                                        clip: true

                                        ScreencopyView {
                                            anchors.fill: parent
                                            captureSource: windowPreview.modelData.wayland
                                            live: overview.shown
                                            constraintSize: Qt.size(windowPreview.width, windowPreview.height)
                                        }

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.bottom: parent.bottom
                                            height: title.implicitHeight + Theme.space(2)
                                            color: Theme.bgDeep
                                            opacity: 0.92

                                            Text {
                                                id: title

                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.margins: Theme.space(1)
                                                text: windowPreview.modelData.title
                                                color: Theme.textSecondary
                                                font: Theme.bodySmall
                                                elide: Text.ElideRight
                                            }
                                        }

                                        HoverHandler {
                                            id: windowHover

                                            cursorShape: Qt.PointingHandCursor
                                            onHoveredChanged: {
                                                if (hovered)
                                                    overview.selectedIndex = workspaceCard.index;
                                            }
                                        }

                                        TapHandler {
                                            onTapped: overview.chooseWindow(windowPreview.modelData)
                                        }
                                    }
                                }
                            }
                        }

                        HoverHandler {
                            cursorShape: Qt.PointingHandCursor
                            onHoveredChanged: {
                                if (hovered)
                                    overview.selectedIndex = workspaceCard.index;
                            }
                        }

                        TapHandler {
                            onTapped: overview.choose(workspaceCard.index)
                        }
                    }
                }

                WheelHandler {
                    onWheel: event => {
                        overview.step(event.angleDelta.y > 0 ? -1 : 1);
                        event.accepted = true;
                    }
                }
            }
        }
    }
}
