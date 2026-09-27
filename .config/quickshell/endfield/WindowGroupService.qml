pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var groups: []
    property bool refreshPending: false
    readonly property bool groupVisible: groups.some(group =>
        Hyprland.monitors.values.some(monitor =>
            monitor.id === group.monitorId
                && monitor.activeWorkspace !== null
                && monitor.activeWorkspace.name === group.workspaceName))

    function buildGroups(clients) {
        const clientsByAddress = {};
        for (const client of clients)
            clientsByAddress[client.address] = client;

        const seen = {};
        const result = [];

        for (const client of clients) {
            if (client.grouped.length < 2)
                continue;

            const key = client.grouped.slice().sort().join(":");
            if (seen[key])
                continue;
            seen[key] = true;

            const members = client.grouped
                .map(address => clientsByAddress[address])
                .filter(member => member !== undefined)
                .map(member => ({
                    address: member.address,
                    className: member.class,
                    title: member.title,
                    visible: member.visible
                }));

            if (members.length < 2)
                continue;

            const visibleMember = members.find(member => member.visible);
            result.push({
                key: key,
                monitorId: client.monitor,
                workspaceName: client.workspace.name,
                x: client.at[0],
                y: client.at[1],
                width: client.size[0],
                activeAddress: visibleMember ? visibleMember.address : members[0].address,
                members: members
            });
        }

        return result;
    }

    function requestRefresh() {
        if (clientsQuery.running) {
            refreshPending = true;
            return;
        }
        clientsQuery.running = true;
    }

    Process {
        id: clientsQuery

        command: ["hyprctl", "clients", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.groups = root.buildGroups(JSON.parse(this.text));
                } catch (error) {
                    console.warn("WindowGroupService: could not read Hyprland clients:", error);
                }
            }
        }

        onRunningChanged: {
            if (running || !root.refreshPending)
                return;
            root.refreshPending = false;
            root.requestRefresh();
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            refreshDelay.restart();
        }
    }

    Timer {
        id: refreshDelay

        interval: 32
        onTriggered: root.requestRefresh()
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.groupVisible
        onTriggered: root.requestRefresh()
    }

    Component.onCompleted: {
        Hyprland.refreshMonitors();
        requestRefresh();
    }
}
