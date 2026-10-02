pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string mode: "xfce"
    property bool busy: false

    function label() {
        return "Xfce display settings";
    }

    function refresh() {}

    function setMode() {
        root.busy = true;
        settings.running = true;
    }

    Process {
        id: settings
        command: ["xfce4-display-settings"]
        onExited: root.busy = false
    }
}
