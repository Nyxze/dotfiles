import ".."
import "../components"
import QtQuick
import QtQuick.Layouts

// A searchable desktop reference. Rofi only hands off to this panel; the shell
// owns the visible interface so it follows the rest of the desktop precisely.
Panel {
    id: shortcutHelp

    readonly property var shortcuts: [
        { section: "HELP", keys: "Super + F1", action: "Open this reference", terms: "shortcuts help keybindings" },
        { section: "HELP", keys: "Super + F, then ?", action: "Open from the app launcher", terms: "shortcuts help launcher rofi" },
        { section: "APPS", keys: "Super + Return", action: "Open terminal", terms: "terminal ghostty" },
        { section: "APPS", keys: "Super + F", action: "Open app launcher", terms: "launcher rofi applications" },
        { section: "APPS", keys: "Super + E", action: "Open files", terms: "files nautilus explorer" },
        { section: "APPS", keys: "Super + B", action: "Open browser", terms: "browser brave web" },
        { section: "APPS", keys: "Super + N", action: "Open editor", terms: "editor code vscode" },
        { section: "WINDOWS", keys: "Super + F4", action: "Close focused window", terms: "close" },
        { section: "WINDOWS", keys: "Super + Shift + F4", action: "Force-close focused window", terms: "kill" },
        { section: "WINDOWS", keys: "Super + H/J/K/L", action: "Focus window by direction", terms: "focus left down up right arrows" },
        { section: "WINDOWS", keys: "Super + H/L", action: "Previous/next window in group", terms: "group tabs" },
        { section: "WINDOWS", keys: "Super + P", action: "Toggle pseudo tiling", terms: "pseudo tile" },
        { section: "WINDOWS", keys: "Super + V", action: "Toggle floating", terms: "float" },
        { section: "WINDOWS", keys: "Super + Shift + F", action: "Toggle fullscreen", terms: "fullscreen" },
        { section: "WINDOWS", keys: "Super + Left click", action: "Drag window", terms: "move mouse" },
        { section: "WINDOWS", keys: "Super + Right click", action: "Resize window", terms: "resize mouse" },
        { section: "WORKSPACES", keys: "Super + 1…5", action: "Switch workspace", terms: "workspace" },
        { section: "WORKSPACES", keys: "Super + Shift + 1…5", action: "Move window to workspace", terms: "workspace move" },
        { section: "WORKSPACES", keys: "Super + 0", action: "Focus Laptop workspace", terms: "laptop" },
        { section: "WORKSPACES", keys: "Super + Space", action: "Change workspace layout", terms: "layout" },
        { section: "WORKSPACES", keys: "Super + G", action: "Group workspace windows", terms: "group" },
        { section: "WORKSPACES", keys: "Super + Tab", action: "Cycle workspace overview", terms: "overview next previous" },
        { section: "CAPTURE", keys: "Super + S", action: "Copy selected screenshot", terms: "screenshot screen capture" },
        { section: "CAPTURE", keys: "Super + Shift + S", action: "Annotate selected screenshot", terms: "screenshot annotation swappy" },
        { section: "CAPTURE", keys: "Print", action: "Save full screenshot", terms: "screenshot screen capture" },
        { section: "CAPTURE", keys: "Super + C", action: "Pick colour to clipboard", terms: "color colour picker clipboard" },
        { section: "PANEL", keys: "Super + D", action: "Toggle system sidebar", terms: "sidebar panel" },
        { section: "PANEL", keys: "Super + Ctrl + C", action: "Open clipboard", terms: "clipboard sidebar" },
        { section: "PANEL", keys: "Super + Ctrl + A", action: "Open audio output", terms: "audio output sound sidebar" },
        { section: "PANEL", keys: "Super + Ctrl + M", action: "Open audio input", terms: "microphone input sidebar" },
        { section: "PANEL", keys: "Super + Ctrl + W", action: "Open network", terms: "wifi network sidebar" },
        { section: "PANEL", keys: "Super + Ctrl + B", action: "Open Bluetooth", terms: "bluetooth sidebar" },
        { section: "PANEL", keys: "Super + Ctrl + D", action: "Open calendar", terms: "calendar sidebar" },
        { section: "PANEL", keys: "Super + Ctrl + P", action: "Open power controls", terms: "power battery sidebar" },
        { section: "SYSTEM", keys: "Super + R", action: "Refresh desktop components", terms: "reload refresh" },
        { section: "SYSTEM", keys: "Super + Shift + L", action: "Lock screen", terms: "lock hyprlock" },
        { section: "SYSTEM", keys: "Ctrl + Alt + Delete", action: "End session", terms: "logout exit" },
        { section: "SYSTEM", keys: "Super + Alt + S", action: "Toggle screen reader", terms: "orca accessibility" },
        { section: "MEDIA", keys: "Volume keys", action: "Volume and mute", terms: "audio volume mute" },
        { section: "MEDIA", keys: "Media keys", action: "Previous, play/pause, next", terms: "music media player" }
    ]

    readonly property var filteredShortcuts: shortcuts.filter(function (entry) {
        const query = search.text.trim().toLowerCase();
        if (query === "")
            return true;

        return (entry.section + " " + entry.keys + " " + entry.action + " " + entry.terms)
            .toLowerCase()
            .includes(query);
    })

    panelTop: true
    panelTopMargin: Math.max(0, (shortcutHelp.screen ? shortcutHelp.screen.height - shortcutHelp.contentHeight : 0) / 2)

    surfaceName: "endfield-shortcut-help"
    panelWidth: Theme.space(180)
    panelHeight: Theme.space(104)
    contentHeight: Theme.space(104)
    exclusionMode: typeof ExclusionMode !== "undefined" ? ExclusionMode.Ignore : 0
    focusTarget: keyCatcher

    function dismiss() {
        closePanel();
    }

    onShownChanged: {
        if (!shown) {
            search.clear();
            Cursor.clear();
            return;
        }
        Qt.callLater(function () {
            if (shortcutHelp.shown)
                search.navActivate();
        });
    }

    Item {
        id: keyCatcher

        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: shortcutHelp.dismiss()

        ColumnLayout {
            id: content

            anchors.fill: parent
            spacing: Theme.space(3)

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space(3)

                Text {
                    text: "KEYBOARD SHORTCUTS"
                    color: Theme.textPrimary
                    font: Theme.h2
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Theme.border
                    color: Theme.line
                }

                Text {
                    text: "ESC CLOSE"
                    color: Theme.textMuted
                    font: Theme.micro
                }
            }

            SearchField {
                id: search

                Layout.fillWidth: true
                placeholder: "Search shortcuts"
                dismissOnEscape: true
                onDismissed: shortcutHelp.closePanel()
            }

            Text {
                Layout.fillWidth: true
                visible: search.text !== ""
                text: shortcutHelp.filteredShortcuts.length + " MATCHES"
                color: Theme.textMuted
                font: Theme.micro
            }

            Flickable {
                id: list

                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: rows.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                Column {
                    id: rows

                    width: list.width
                    spacing: Theme.space(1)

                    Repeater {
                        model: shortcutHelp.filteredShortcuts

                        delegate: ShortcutRow {
                            required property var modelData

                            width: rows.width
                            section: modelData.section
                            keys: modelData.keys
                            action: modelData.action
                        }
                    }
                }
            }
        }
    }
}
