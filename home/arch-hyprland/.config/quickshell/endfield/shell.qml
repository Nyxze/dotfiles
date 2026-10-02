import Quickshell
import Quickshell.Io
import "examples"
import "panels"

// Entry point. Mounts each panel and exposes it over IPC; panels own their own
// layout and content, the shell only wires them up.
ShellRoot {
    Sidebar {
        id: sidebar
    }

    WorkspaceOverview {
        id: workspaceOverview
    }

    ShortcutHelp {
        id: shortcutHelp
    }

    GroupBars {}

    Lock {
        id: lockScreen
    }

    Toasts {
        // Keep toasts clear of the sidebar while it is open.
        sideOffset: sidebar.shown ? sidebar.implicitWidth + 10 : 0
    }

    // Disposable: a stage for NavRow while its shape is being settled. Delete
    // this block, the handler below it and the examples import to drop it.
    NavRowDemo {
        id: navDemo
    }

    IpcHandler {
        target: "navdemo"

        function toggle(): void {
            navDemo.toggle();
        }
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

        // Lets a keybind land straight on a detail page, and is how the panel
        // gets driven during headless screenshot runs.
        function page(name: string): void {
            sidebar.openPanel();
            sidebar.page = name;
        }
    }

    IpcHandler {
        target: "overview"

        function next(): void {
            workspaceOverview.step(1);
        }

        function previous(): void {
            workspaceOverview.step(-1);
        }

        function accept(): void {
            workspaceOverview.accept();
        }

        function cancel(): void {
            workspaceOverview.dismiss();
        }
    }

    IpcHandler {
        target: "shortcuts"

        function toggle(): void {
            shortcutHelp.toggle();
        }

        function open(): void {
            shortcutHelp.openPanel();
        }

        function close(): void {
            shortcutHelp.closePanel();
        }
    }

    IpcHandler {
        target: "lock"

        // hypridle and the keybind both land here. Locking is idempotent:
        // several listeners firing at once must not stack two surfaces.
        function lock(): void {
            lockScreen.lock();
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
