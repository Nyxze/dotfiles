import QtQuick
import Quickshell
import "services"
pragma Singleton

Singleton {
    id: root

    readonly property int pageSize: 10
    readonly property int maximumEntries: 10
    property var entries: []
    property var history: []
    property bool active: false
    property bool captureEnabled: true
    property bool loading: false
    property bool hasMore: false
    property string query: ""
    property string error: ""
    property int lastSequence: -1
    property int listGeneration: 0
    property string nextCursor: ""
    readonly property bool available: client.watchReady
    readonly property bool busy: loading || !client.idle
    readonly property bool reconnecting: active && !client.watchReady

    function setActive(on) {
        active = on;
        if (!on) {
            setQuery("");
            return ;
        }
        refresh();
        client.request("status", {
        }, {
        });
    }

    function setQuery(text) {
        const next = text.trim();
        if (query === next)
            return ;

        query = next;
        if (!active) {
            entries = history;
            hasMore = false;
            return ;
        }
        searchTimer.restart();
    }

    function refresh() {
        listGeneration += 1;
        nextCursor = "";
        loading = true;
        client.request("list", listParams(""), {
            "generation": listGeneration,
            "append": false,
            "query": query
        });
    }

    function loadMore() {
        if (loading || !hasMore || nextCursor === "")
            return ;

        loading = true;
        client.request("list", listParams(nextCursor), {
            "generation": listGeneration,
            "append": true,
            "query": query
        });
    }

    function copy(id) {
        client.request("copy", {
            "id": String(id)
        }, {
        });
    }

    function remove(id) {
        client.request("delete", {
            "id": String(id),
            "ignoreMissing": true
        }, {
        });
    }

    function togglePinned(item) {
        client.request(item.pinned ? "unpin" : "pin", {
            "id": String(item.id)
        }, {
        });
    }

    function clear(includePinned) {
        client.request("clear", {
            "includePinned": includePinned === true
        }, {
        });
    }

    function setCapture(enabled) {
        client.request(enabled ? "resume" : "pause", {
        }, {
        });
    }

    function listParams(cursor) {
        const params = {
            "limit": pageSize
        };
        if (query !== "")
            params.query = query;

        if (cursor !== "")
            params.cursor = cursor;

        return params;
    }

    function handleResult(operation, result, context) {
        error = "";
        if (operation === "list") {
            applyList(result, context);
            return ;
        }
        if (operation === "status") {
            if (result.captureEnabled !== undefined)
                captureEnabled = result.captureEnabled;

            return ;
        }
        if (operation === "pin" || operation === "unpin") {
            if (result.item !== undefined)
                updateHistory(result.item);

            return ;
        }
        if (operation === "clear") {
            refresh();
            return ;
        }
        if (operation === "pause" || operation === "resume") {
            if (result.captureEnabled !== undefined)
                captureEnabled = result.captureEnabled;

        }
    }

    function applyList(result, context) {
        if (context.generation !== listGeneration || context.query !== query)
            return ;

        const items = Array.isArray(result.items) ? result.items : [];
        if (context.append)
            entries = bounded(merge(entries, items));
        else
            entries = bounded(items);
        if (query === "")
            history = entries;

        nextCursor = typeof result.cursor === "string" ? result.cursor : "";
        hasMore = nextCursor !== "" && entries.length < maximumEntries;
        loading = false;
    }

    function handleEvent(message) {
        const sequence = Number(message.sequence);
        if (message.event === "snapshot") {
            lastSequence = sequence;
            history = bounded(Array.isArray(message.items) ? message.items : []);
            if (query === "") {
                entries = history;
                nextCursor = typeof message.cursor === "string" ? message.cursor : "";
                hasMore = nextCursor !== "" && entries.length < maximumEntries;
            }
            return ;
        }
        if (sequence <= lastSequence)
            return ;

        if (lastSequence >= 0 && sequence !== lastSequence + 1) {
            error = "Clipboard history changed while disconnected";
            client.reconnectWatch();
            return ;
        }
        lastSequence = sequence;
        if (message.event === "item.added" || message.event === "item.updated") {
            updateHistory(message.item);
        } else if (message.event === "item.removed") {
            removeFromHistory(message.id);
        } else if (message.event === "history.cleared") {
            history = [];
            if (query === "")
                entries = [];

            if (active)
                refresh();

        } else if (message.event === "capture.changed")
            captureEnabled = message.enabled;
        else if (message.event === "capture.rejected")
            error = message.reason || "Clipboard capture was rejected";
        if (query !== "" && active)
            searchTimer.restart();

    }

    function updateHistory(item) {
        if (!item || item.id === undefined)
            return ;

        history = bounded([item].concat(withoutId(history, item.id)));
        if (query === "")
            entries = history;

    }

    function removeFromHistory(id) {
        history = withoutId(history, id);
        entries = withoutId(entries, id);
    }

    function withoutId(items, id) {
        return items.filter((item) => {
            return String(item.id) !== String(id);
        });
    }

    function merge(existing, incoming) {
        let merged = existing.slice();
        for (const item of incoming) {
            if (item && item.id !== undefined)
                merged = merged.concat([item]);

        }
        const seen = {
        };
        return merged.filter((item) => {
            const id = String(item.id);
            if (seen[id] === true)
                return false;

            seen[id] = true;
            return true;
        });
    }

    function bounded(items) {
        return items.slice(0, maximumEntries);
    }

    MimiclipClient {
        id: client

        onSucceeded: (operation, result, context) => {
            return root.handleResult(operation, result, context);
        }
        onFailed: (operation, message, context) => {
            if (operation === "list")
                root.loading = false;

            root.error = message;
        }
        onEventReceived: (message) => {
            return root.handleEvent(message);
        }
        onTransportError: (message) => {
            if (root.active)
                root.error = message;

        }
    }

    Timer {
        id: searchTimer

        interval: 180
        repeat: false
        onTriggered: root.refresh()
    }

}
