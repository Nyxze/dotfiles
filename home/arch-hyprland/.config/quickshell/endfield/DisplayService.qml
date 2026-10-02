pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/displays.py"

    property string mode: "extend"
    property bool busy: false

    function label(name) {
        switch (name) {
        case "mirror":
            return "Mirror";
        case "external":
            return "External only";
        case "internal":
            return "Internal only";
        default:
            return "Extend";
        }
    }

    function refresh() {
        query.running = true;
    }

    function setMode(name) {
        if (root.busy || !["extend", "mirror", "external", "internal"].includes(name))
            return;
        root.busy = true;
        setter.command = [root.script, name];
        setter.running = true;
    }

    Process {
        id: query
        command: [root.script, "status"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const value = this.text.trim();
                if (["extend", "mirror", "external", "internal"].includes(value))
                    root.mode = value;
            }
        }
    }

    Process {
        id: setter
        onExited: {
            root.busy = false;
            root.refresh();
        }
    }
}
