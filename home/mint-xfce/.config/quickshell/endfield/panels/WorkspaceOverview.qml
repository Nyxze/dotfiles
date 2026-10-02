import ".."
import "../components"
import Quickshell.Io
import Quickshell.I3
import QtQuick
import QtQuick.Layouts

// i3 exposes workspace metadata, not Wayland screencopy. The V1 overview uses
// the workspace name, its focus state, and i3's window count instead.
Panel {
    id: overview

    readonly property var workspaceNames: ["1", "2", "3", "4", "5"]
    property int selectedIndex: 0
    property var snapshots: ({})

    function snapshotTree(node, next) {
        if (node.type === "workspace") {
            const windows = [];
            collectWindows(node, windows);
            next[node.name] = windows;
        }
        for (const child of (node.nodes || []))
            snapshotTree(child, next);
    }

    function collectWindows(node, windows) {
        if (node.window !== null && node.window !== undefined) {
            windows.push({
                title: node.name || "Untitled window",
                className: node.window_properties ? node.window_properties.class || "" : ""
            });
        }
        for (const child of (node.nodes || []).concat(node.floating_nodes || []))
            collectWindows(child, windows);
    }

    function refreshSnapshots() { treeQuery.running = true; }

    function workspaceAt(index) {
        return I3.workspaces.values.find(workspace => workspace.name === workspaceNames[index]) || null;
    }

    function focusedIndex() {
        const focused = I3.focusedWorkspace;
        const index = focused ? workspaceNames.indexOf(focused.name) : 0;
        return index < 0 ? 0 : index;
    }

    function step(direction) {
        if (!shown) {
            I3.refreshWorkspaces();
            refreshSnapshots();
            selectedIndex = focusedIndex();
            openPanel();
        }
        selectedIndex = (selectedIndex + direction + workspaceNames.length) % workspaceNames.length;
    }

    function accept() {
        const workspace = workspaceAt(selectedIndex);
        if (workspace)
            workspace.activate();
        else
            I3.dispatch("workspace number " + workspaceNames[selectedIndex]);
        closePanel();
    }

    function dismiss() { closePanel(); }

    anchors { top: true; left: true; right: true; bottom: true }
    margins { top: Theme.space(10); left: Theme.space(10); right: Theme.space(10); bottom: Theme.space(10) }
    contentHeight: Math.min(overview.height, Theme.space(72))

    Process {
        id: treeQuery
        command: ["i3-msg", "-t", "get_tree", "-r"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const next = {};
                    overview.snapshotTree(JSON.parse(this.text), next);
                    overview.snapshots = next;
                } catch (error) {
                    console.warn("WorkspaceOverview: could not read the i3 tree:", error);
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) overview.dismiss();
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) overview.accept();
            else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) overview.step(-1);
            else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) overview.step(1);
            else return;
            event.accepted = true;
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: Theme.space(4)

            Text { text: "WORKSPACES"; color: Theme.textPrimary; font: Theme.h2 }

            RowLayout {
                Layout.fillWidth: true
                Repeater {
                    model: overview.workspaceNames
                    delegate: Item {
                        required property int index
                        required property string modelData
                        readonly property var workspace: overview.workspaceAt(index)
                        readonly property var windows: overview.snapshots[modelData] || []
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ChamferedRect {
                            anchors.fill: parent
                            topRight: true
                            bottomLeft: true
                            color: index === overview.selectedIndex ? Theme.bgRaised : Theme.bgDeep
                            borderColor: index === overview.selectedIndex ? Theme.accent : Theme.line
                            borderWidth: index === overview.selectedIndex ? Theme.borderEmphasis : Theme.border
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.space(3)
                            Text { text: modelData; color: Theme.textPrimary; font: Theme.h2 }
                            Text { text: windows.length + (windows.length === 1 ? " WINDOW" : " WINDOWS"); color: Theme.textSecondary; font: Theme.micro }
                            Text { text: workspace && workspace.focused ? "FOCUSED" : ""; color: Theme.accent; font: Theme.micro }
                            Repeater {
                                model: windows.slice(0, 3)
                                delegate: Text {
                                    required property var modelData
                                    width: parent.width
                                    text: "󰆍  " + modelData.title
                                    color: Theme.textMuted
                                    font: Theme.micro
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        TapHandler { onTapped: { overview.selectedIndex = index; overview.accept(); } }
                    }
                }
            }
        }
    }
}
