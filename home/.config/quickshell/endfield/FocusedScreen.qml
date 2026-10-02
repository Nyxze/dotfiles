pragma Singleton

import Quickshell
import Quickshell.Io

// Resolves the ShellScreen a panel should open on.
//
// Quickshell's Hyprland.focusedMonitor cannot be used: it is never seeded at
// startup and stays null until a focus change happens after Quickshell
// launches, and refreshMonitors() fills the monitor list without setting the
// focused flag. Asking hyprctl each time is one subprocess per panel opening,
// which is not worth optimising.
Singleton {
    id: root

    property var pending: null

    Process {
        id: query
        command: ["hyprctl", "monitors", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                let resolved = null;
                try {
                    const monitors = JSON.parse(this.text);
                    for (const monitor of monitors) {
                        if (!monitor.focused)
                            continue;
                        for (const screen of Quickshell.screens) {
                            if (screen.name === monitor.name)
                                resolved = screen;
                        }
                        break;
                    }
                } catch (e) {
                    console.warn("FocusedScreen: could not read hyprctl monitors:", e);
                }

                const callback = root.pending;
                root.pending = null;
                if (callback)
                    callback(resolved);
            }
        }
    }

    // Calls back with the focused ShellScreen, or null if it could not be
    // determined — callers should keep whatever screen they already had.
    function resolve(callback) {
        pending = callback;
        query.running = true;
    }
}
