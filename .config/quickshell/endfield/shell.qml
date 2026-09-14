import Quickshell
import Quickshell.Io
import "panels"

// Entry point. Mounts each panel and exposes it over IPC; panels own their own
// layout and content, the shell only wires them up.
ShellRoot {
    CalendarPanel {
        id: calendar
    }

    IpcHandler {
        target: "calendar"

        function toggle(): void {
            calendar.toggle();
        }

        function show(): void {
            calendar.openPanel();
        }

        function hide(): void {
            calendar.closePanel();
        }
    }
}
