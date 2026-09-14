import Quickshell
import Quickshell.Io
import "panels"

// Entry point. Mounts each panel and exposes it over IPC; panels own their own
// layout and content, the shell only wires them up.
ShellRoot {
    Sidebar {
        id: sidebar
    }

    IpcHandler {
        target: "sidebar"

        function toggle(): void {
            sidebar.toggle();
        }

        function open(): void {
            sidebar.openPanel();
        }

        function close(): void {
            sidebar.closePanel();
        }
    }
}
