import ".."
import "../components"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page

    signal picked()

    function kindLabel(entry) {
        switch (entry.kind) {
        case "image":
            return "IMAGE";
        case "html":
            return "HTML";
        case "files":
            return "FILES";
        case "binary":
            return "BINARY";
        default:
            return "TEXT";
        }
    }

    function glyph(entry) {
        switch (entry.kind) {
        case "image":
            return "󰋩";
        case "files":
            return "󰉋";
        case "html":
            return "󰅩";
        default:
            return "󰅍";
        }
    }

    function label(entry) {
        if (entry.preview && entry.preview.trim() !== "")
            return entry.preview;

        if (entry.kind === "image")
            return "Image from clipboard";

        if (entry.kind === "files")
            return "Files from clipboard";

        return "Binary clipboard data";
    }

    spacing: Theme.space(4)
    Component.onCompleted: ClipboardService.setActive(true)
    Component.onDestruction: ClipboardService.setActive(false)

    PageHeader {
        Layout.fillWidth: true
        glyph: "󰅍"
        title: ClipboardService.entries.length + " saved item" + (ClipboardService.entries.length === 1 ? "" : "s") + (ClipboardService.hasMore ? "+" : "")
        subtitle: ClipboardService.available ? "MIMICLIP · " + (ClipboardService.captureEnabled ? "CAPTURING" : "PAUSED") : (ClipboardService.reconnecting ? "MIMICLIP · RECONNECTING" : "MIMICLIP · UNAVAILABLE")
        dimmed: !ClipboardService.available

        IconButton {
            glyph: ClipboardService.captureEnabled ? "󰏤" : "󰐊"
            onActivated: ClipboardService.setCapture(!ClipboardService.captureEnabled)
        }

        IconButton {
            enabled: ClipboardService.entries.length > 0
            opacity: enabled ? 1 : 0.4
            glyph: "󰩹"
            onActivated: ClipboardService.clear(false)
        }

    }

    SearchField {
        Layout.fillWidth: true
        placeholder: "Search clipboard history"
        onTextChanged: ClipboardService.setQuery(text)
    }

    Text {
        Layout.fillWidth: true
        visible: ClipboardService.error !== ""
        text: ClipboardService.error
        color: Theme.danger
        font: Theme.bodySmall
        wrapMode: Text.Wrap
    }

    Text {
        Layout.fillWidth: true
        visible: ClipboardService.available && !ClipboardService.loading && ClipboardService.entries.length === 0
        text: ClipboardService.query === "" ? "Clipboard history is empty" : "No matching item"
        color: Theme.line
        font: Theme.body
    }

    Text {
        Layout.fillWidth: true
        visible: ClipboardService.loading && ClipboardService.entries.length === 0
        text: "Loading clipboard history…"
        color: Theme.textMuted
        font: Theme.body
    }

    Section {
        Layout.fillWidth: true
        visible: ClipboardService.entries.length > 0
        title: ClipboardService.query === "" ? "Recent" : "Matches"

        Repeater {
            model: ClipboardService.entries

            RowLayout {
                required property var modelData

                Layout.fillWidth: true
                spacing: Theme.space(1)

                ListRow {
                    id: entryRow

                    function navAdjust(step) {
                        ClipboardService.togglePinned(modelData);
                    }

                    Layout.fillWidth: true
                    glyph: page.glyph(modelData)
                    label: page.label(modelData)
                    trailing: (modelData.pinned ? "PINNED · " : "") + page.kindLabel(modelData)
                    actionGlyph: "󰆴"
                    onActivated: {
                        ClipboardService.copy(modelData.id);
                        page.picked();
                    }
                    onActionActivated: ClipboardService.remove(modelData.id)
                }

                IconButton {
                    cursorTarget: entryRow
                    glyph: modelData.pinned ? "󰐃" : "󰤱"
                    onActivated: ClipboardService.togglePinned(modelData)
                }

            }

        }

        ListRow {
            Layout.fillWidth: true
            visible: ClipboardService.hasMore
            enabled: !ClipboardService.loading
            opacity: enabled ? 1 : 0.4
            glyph: "󰁅"
            label: ClipboardService.loading ? "Loading…" : "Load more"
            trailing: ClipboardService.entries.length + " / " + ClipboardService.maximumEntries
            onActivated: ClipboardService.loadMore()
        }

    }

}
