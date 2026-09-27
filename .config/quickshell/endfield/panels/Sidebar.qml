import ".."
import "../components"
import "../pages"
import "../widgets"
import QtQuick
import QtQuick.Layouts

// Quick settings: a fixed head that never scrolls — clock, tiles, levels — over
// a content region that swaps between detail pages. Notifications are the
// resting page, so closing a detail view lands back on the feed.
Panel {
    id: sidebar

    // One list drives the rail and the heading; the loader below maps the key
    // to a component, which the array cannot hold — ids do not resolve from
    // inside a property literal.
    readonly property var pages: [
        {
            key: "notifications",
            title: "Notifications",
            glyph: "󰂚"
        },
        {
            key: "clipboard",
            title: "Clipboard",
            glyph: "󰅍"
        },
        {
            key: "output",
            title: "Output",
            glyph: "󰕾"
        },
        {
            key: "input",
            title: "Input",
            glyph: "󰍬"
        },
        {
            key: "network",
            title: "Network",
            glyph: "󰤨"
        },
        {
            key: "bluetooth",
            title: "Bluetooth",
            glyph: "󰂯"
        },
        {
            key: "displays",
            title: "Displays",
            glyph: "󰍺"
        },
        {
            key: "calendar",
            title: "Calendar",
            glyph: "󰃭"
        },
        {
            key: "power",
            title: "Power",
            glyph: "󰐥"
        }
    ]

    property string page: "notifications"

    readonly property var currentPage: pages.find(entry => entry.key === page) || pages[0]

    // Clicking the chevron that is already open goes back, so a tile is both
    // the way in and the way out. The rail selects outright instead.
    function openPage(name) {
        page = page === name ? "notifications" : name;
    }

    // Escape leaves the page before it leaves the panel.
    function dismiss() {
        if (page !== "notifications")
            page = "notifications";
        else
            closePanel();
    }

    // The item tree is rebuilt by Loaders and Repeaters (a page swap, a Wi-Fi
    // scan) far more often than any signal fires for it, so the navigable
    // list is rescanned on demand rather than bound.
    function focusables() {
        const out = [];
        collect(stack, out);
        return out;
    }

    function collect(item, out) {
        for (const child of item.children) {
            if (child.navigable === true && child.visible) {
                out.push(child); // navigable items are stops, never containers
                continue;
            }
            collect(child, out);
        }
    }

    // Rows are decided from geometry, not from parent type: two sliders
    // stacked one above the other stay two separate stops, so h/l adjusts a
    // slider instead of hopping to the next row.
    function centreOf(item) {
        return item.mapToItem(null, 0, item.height / 2).y;
    }

    function groupRows(items) {
        const rows = [];
        for (const item of items) {
            if (rows.length > 0) {
                const row = rows[rows.length - 1];
                const prev = row[row.length - 1];
                if (Math.abs(centreOf(item) - centreOf(prev)) < Math.min(item.height, prev.height) / 2) {
                    row.push(item);
                    continue;
                }
            }
            rows.push([item]);
        }
        return rows;
    }

    function locate(rows, item) {
        for (let r = 0; r < rows.length; r++) {
            const c = rows[r].indexOf(item);
            if (c !== -1)
                return { row: r, col: c };
        }
        return null;
    }

    // The one place Cursor.item and Cursor.index are written together, so a
    // rescan and a keypress can never leave them disagreeing.
    function place(items, item) {
        Cursor.item = item;
        Cursor.index = items.indexOf(item);
        scrollIntoView(item);
    }

    // A Wi-Fi scan or a page swap destroys and recreates delegates, which
    // reads back as Cursor.item turning null out from under the cursor.
    // Recover from the remembered index instead of dropping the highlight.
    function reconcile(items) {
        if (Cursor.index === -1)
            return;
        const list = items || focusables();
        if (list.length === 0)
            return;
        if (Cursor.item && list.indexOf(Cursor.item) !== -1)
            return;
        place(list, list[Math.min(Cursor.index, list.length - 1)]);
    }

    function moveCursor(dx, dy) {
        const items = focusables();
        if (items.length === 0)
            return;

        // A stray keypress on a fresh panel only reveals the cursor; it must
        // never also act as a move.
        if (Cursor.index === -1) {
            place(items, items[0]);
            return;
        }

        reconcile(items);
        const rows = groupRows(items);
        const at = locate(rows, Cursor.item);
        if (!at)
            return;

        if (dy !== 0) {
            const targetRow = at.row + dy;
            if (targetRow < 0 || targetRow >= rows.length)
                return;
            const row = rows[targetRow];
            place(items, row[Math.min(at.col, row.length - 1)]);
            return;
        }

        if (dx !== 0) {
            if (typeof Cursor.item.navAdjust === "function") {
                Cursor.item.navAdjust(dx);
                return;
            }
            const row = rows[at.row];
            const col = at.col + dx;
            if (col < 0 || col >= row.length)
                return;
            place(items, row[col]);
        }
    }

    function activateCursor() {
        if (Cursor.item)
            Cursor.item.navActivate();
    }

    function removeAtCursor() {
        if (Cursor.item && typeof Cursor.item.navRemove === "function")
            Cursor.item.navRemove();
    }

    function cyclePage(direction) {
        const idx = pages.findIndex(entry => entry.key === page);
        page = pages[(idx + direction + pages.length) % pages.length].key;
    }

    function insideContent(item) {
        for (let node = item; node !== null; node = node.parent) {
            if (node === content)
                return true;
        }
        return false;
    }

    function scrollIntoView(item) {
        if (!insideContent(item))
            return;
        if (scroller.contentHeight <= scroller.height)
            return;
        const pos = item.mapToItem(content, 0, 0).y;
        const bottom = pos + item.height;
        if (pos < scroller.contentY)
            scroller.contentY = pos;
        else if (bottom > scroller.contentY + scroller.height)
            scroller.contentY = bottom - scroller.height;
    }

    anchors {
        top: true
        right: true
        bottom: true
    }

    margins {
        top: 10
        right: 10
        bottom: 10
    }

    surfaceName: "endfield-sidebar"
    implicitWidth: 380
    focusTarget: keyCatcher

    // Grow with the content instead of always spanning the screen: an empty
    // notification feed left most of a full-height panel as dead space.
    contentHeight: stack.implicitHeight + 2 * Theme.padding

    onShownChanged: {
        if (shown)
            return;
        page = "notifications";
        Cursor.clear();
    }

    KeyCatcher {
        id: keyCatcher
        anchors.fill: parent

        onDismissed: sidebar.dismiss()
        onMoved: (dx, dy) => sidebar.moveCursor(dx, dy)
        onActivated: sidebar.activateCursor()
        onRemoved: sidebar.removeAtCursor()
        onTabbed: direction => sidebar.cyclePage(direction)

        ColumnLayout {
            id: stack

            anchors.fill: parent
            spacing: Theme.space(4)

            SidebarHeader {
                Layout.fillWidth: true
                onPageRequested: name => sidebar.openPage(name)
            }

            QuickTiles {
                Layout.fillWidth: true
                onPageRequested: name => sidebar.openPage(name)
            }

            VolumeControls {
                Layout.fillWidth: true
                onPageRequested: name => sidebar.openPage(name)
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: Theme.space(1)
                implicitHeight: Theme.border
                color: Theme.line
            }

            PageRail {
                Layout.fillWidth: true
                pages: sidebar.pages
                current: sidebar.page
                onSelected: key => sidebar.page = key
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space(2)

                Text {
                    Layout.fillWidth: true
                    text: sidebar.currentPage.title
                    color: Theme.textMuted
                    font: Theme.label
                }

                IconButton {
                    visible: sidebar.page === "notifications"
                        && NotificationService.historyIds.length > 0
                    glyph: "󰩹"
                    onActivated: NotificationService.clearHistory()
                }
            }

            Flickable {
                id: scroller

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: contentHeight
                contentHeight: content.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                Loader {
                    id: content

                    width: scroller.width
                    height: implicitHeight

                    sourceComponent: {
                        switch (sidebar.page) {
                        case "clipboard":
                            return clipboardPage;
                        case "output":
                            return outputPage;
                        case "input":
                            return inputPage;
                        case "network":
                            return networkPage;
                        case "bluetooth":
                            return bluetoothPage;
                        case "displays":
                            return displaysPage;
                        case "calendar":
                            return calendarPage;
                        case "power":
                            return powerPage;
                        default:
                            return notificationsPage;
                        }
                    }
                }
            }
        }
    }

    // Only ticks while the panel is open, so a rebuilt list catches up to the
    // cursor even if no key is pressed right after it (e.g. a Wi-Fi scan).
    Timer {
        interval: 250
        repeat: true
        running: sidebar.shown
        onTriggered: sidebar.reconcile()
    }

    Component {
        id: notificationsPage

        NotificationsPage {}
    }

    Component {
        id: clipboardPage

        ClipboardPage {
            onPicked: sidebar.closePanel()
        }
    }

    Component {
        id: outputPage

        OutputPage {}
    }

    Component {
        id: inputPage

        InputPage {}
    }

    Component {
        id: networkPage

        NetworkPage {}
    }

    Component {
        id: bluetoothPage

        BluetoothPage {}
    }

    Component {
        id: displaysPage

        DisplaysPage {}
    }

    Component {
        id: calendarPage

        CalendarPage {}
    }

    Component {
        id: powerPage

        PowerPage {}
    }
}
