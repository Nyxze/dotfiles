pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// TLP rather than power-profiles-daemon, so UPower.PowerProfiles reports
// nothing on this machine. tlp-stat reads the mode without root; switching it
// goes through pkexec and will ask for a password.
Singleton {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.local/scripts/tlp-ctl"

    property string mode: "…"

    // tlp-stat spells the mode differently across versions ("battery",
    // "powersave/BAT"), so match the stem rather than the whole string.
    readonly property bool onBattery: mode.toLowerCase().includes("bat")

    // tlp-stat appends "(manual)" once a mode has been forced; without it
    // TLP is still switching on AC/battery by itself.
    readonly property bool manual: mode.includes("(manual)")

    function matches(name) {
        if (name === "auto")
            return !manual;
        return manual && (name === "bat" ? onBattery : !onBattery);
    }

    function refresh() {
        query.running = true;
    }

    function toggle() {
        setMode(onBattery ? "ac" : "bat");
    }

    function setMode(name) {
        setter.command = [script, "set", name];
        setter.running = true;
    }

    Process {
        id: query
        command: ["tlp-stat", "-m"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.mode = this.text.trim() || "unknown"
        }
    }

    Process {
        id: setter
        onExited: root.refresh()
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
