// A stage for NavRow, so the selector can be handled rather than read about:
//
//     qs -c endfield ipc call navdemo toggle
//
// j/k walks, Enter selects, Escape closes. Disposable — it is mounted from
// shell.qml by four lines that can go once the component has earned its keep.

import ".."
import "../components"
import Quickshell
import QtQuick
import QtQuick.Layouts

Panel {
    id: demo

    readonly property var entries: [
        { key: "continue", glyph: "󰐊", title: "Continue", subtitle: "Main Story · Chapter 3-2" },
        { key: "operation", glyph: "󰒓", title: "Operation", subtitle: "Event & Challenge" },
        { key: "operators", glyph: "󰀄", title: "Operators", subtitle: "Squad Management" },
        { key: "base", glyph: "󰠮", title: "Base", subtitle: "Building & Facilities" },
        { key: "inventory", glyph: "󰈸", title: "Inventory", subtitle: "Items & Equipment" },
        { key: "settings", glyph: "󰢻", title: "Settings", subtitle: "System Config" }
    ]

    property string current: "continue"

    function stops() {
        const found = [];
        for (const child of column.children)
            if (child.navigable)
                found.push(child);
        return found;
    }

    anchors {
        top: true
        left: true
        bottom: true
    }

    margins {
        top: 10
        left: 10
        bottom: 10
    }

    surfaceName: "endfield-navdemo"
    implicitWidth: 460
    focusTarget: keyCatcher
    contentHeight: column.implicitHeight + 2 * Theme.padding

    onShownChanged: if (!shown) Cursor.clear()

    KeyCatcher {
        id: keyCatcher
        anchors.fill: parent

        onDismissed: demo.closePanel()
        onActivated: if (Cursor.item) Cursor.item.navActivate()
        onMoved: (dx, dy) => {
            const all = demo.stops();
            if (all.length === 0)
                return;
            const at = all.indexOf(Cursor.item);
            Cursor.item = at < 0 ? all[0] : all[(at + dy + all.length) % all.length];
        }
    }

    ColumnLayout {
        id: column

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Theme.space(3)

        Section {
            Layout.fillWidth: true
            title: "Navigation"
        }

        Repeater {
            model: demo.entries

            NavRow {
                required property var modelData

                Layout.fillWidth: true

                glyph: modelData.glyph
                title: modelData.title
                subtitle: modelData.subtitle
                selected: modelData.key === demo.current

                onActivated: demo.current = modelData.key
            }
        }
    }
}
