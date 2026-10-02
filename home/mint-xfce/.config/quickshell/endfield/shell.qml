import Quickshell
import Quickshell.Io
import "examples"
import "panels"

ShellRoot {
    Sidebar { id: sidebar }
    WorkspaceOverview { id: workspaceOverview }
    ShortcutHelp { id: shortcutHelp }

    IpcHandler {
        target: "sidebar"
        function toggle() { sidebar.toggle(); }
        function open() { sidebar.openPanel(); }
        function close() { sidebar.closePanel(); }
        function page(name: string) { sidebar.openPanel(); sidebar.page = name; }
    }

    IpcHandler {
        target: "overview"
        function next() { workspaceOverview.step(1); }
        function previous() { workspaceOverview.step(-1); }
        function accept() { workspaceOverview.accept(); }
        function cancel() { workspaceOverview.dismiss(); }
    }

    IpcHandler {
        target: "shortcuts"
        function toggle() { shortcutHelp.toggle(); }
        function open() { shortcutHelp.openPanel(); }
        function close() { shortcutHelp.closePanel(); }
    }

    IpcHandler {
        target: "notifications"
        function dnd() { NotificationService.doNotDisturb = !NotificationService.doNotDisturb; }
        function clear() { NotificationService.clearHistory(); }
    }
}
