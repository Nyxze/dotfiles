import Quickshell
import Quickshell.Io
import "panels"

// Entry point. Mounts each panel and exposes it over IPC; panels own their own
// layout and content, the shell only wires them up.
ShellRoot {
    Sidebar {
        id: sidebar
    }

    Toasts {
        // Keep toasts clear of the sidebar while it is open.
        sideOffset: sidebar.shown ? sidebar.implicitWidth + 10 : 0
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

    IpcHandler {
        target: "notifications"

        function dnd(): void {
            NotificationService.doNotDisturb = !NotificationService.doNotDisturb;
        }

        function clear(): void {
            NotificationService.clearHistory();
        }
    }
}
