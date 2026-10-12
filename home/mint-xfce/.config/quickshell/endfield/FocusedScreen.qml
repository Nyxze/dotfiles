pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    Process {
        id: focusedOutput
        property var pendingCallback: null
        command: ["i3-msg", "-t", "get_workspaces", "-r"]
        stdout: StdioCollector {
            onStreamFinished: {
                let output = "";
                try {
                    output = JSON.parse(this.text).find(workspace => workspace.focused).output;
                } catch (error) {
                    console.warn("FocusedScreen: could not read focused i3 output:", error);
                }
                const screen = Quickshell.screens.find(candidate => candidate.name === output)
                    || (Quickshell.screens.length ? Quickshell.screens[0] : null);
                if (focusedOutput.pendingCallback)
                    focusedOutput.pendingCallback(screen);
                focusedOutput.pendingCallback = null;
            }
        }
    }

    function resolve(callback) {
        focusedOutput.pendingCallback = callback;
        focusedOutput.running = true;
    }
}
