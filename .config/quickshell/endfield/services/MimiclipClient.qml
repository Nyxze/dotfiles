import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: client

    readonly property int protocolVersion: 2
    readonly property string runtimeDirectory: Quickshell.env("XDG_RUNTIME_DIR")
    readonly property string socketPath: {
        const override = Quickshell.env("MIMICLIP_SOCKET") || "";
        return override !== "" ? override : runtimeDirectory + "/mimiclip.sock";
    }
    property bool commandReady: false
    property bool watchReady: false
    property int nextRequestId: 1
    property var pending: ({
    })
    property var queued: []
    property string commandHelloId: ""
    property string watchHelloId: ""
    property string watchRequestId: ""
    property int commandBackoffMs: 250
    property int watchBackoffMs: 250
    readonly property bool idle: queued.length === 0 && Object.keys(pending).length === 0
    property Socket commandSocket
    property Socket watchSocket
    property Timer commandRetry
    property Timer watchRetry

    signal succeeded(string operation, var result, var context)
    signal failed(string operation, string message, var context)
    signal eventReceived(var message)
    signal transportError(string message)

    function request(operation, parameters, context) {
        if (operation === "list")
            queued = queued.filter((request) => {
            return request.operation !== "list";
        });

        queued = queued.concat([{
            "operation": operation,
            "parameters": parameters,
            "context": context
        }]);
        flushQueue();
    }

    function reconnectWatch() {
        watchSocket.connected = false;
    }

    function start() {
        ensureCommandConnected();
        if (!watchSocket.connected)
            watchSocket.connected = true;
    }

    function flushQueue() {
        if (!commandReady) {
            ensureCommandConnected();
            return ;
        }
        const requests = queued;
        queued = [];
        for (const request of requests) sendCommand(request.operation, request.parameters, request.context)
    }

    function sendCommand(operation, parameters, context) {
        const id = requestId("command");
        const nextPending = Object.assign({
        }, pending);
        nextPending[id] = {
            "operation": operation,
            "context": context
        };
        pending = nextPending;
        write(commandSocket, {
            "id": id,
            "op": operation,
            "params": parameters
        });
    }

    function requestId(channel) {
        const id = "quickshell-" + channel + "-" + nextRequestId;
        nextRequestId += 1;
        return id;
    }

    function write(socket, message) {
        socket.write(JSON.stringify(message) + "\n");
        socket.flush();
    }

    function ensureCommandConnected() {
        if (commandSocket.connected || commandRetry.running)
            return ;

        commandSocket.connected = true;
    }

    function handleCommandConnection(connected) {
        if (!connected) {
            commandReady = false;
            commandHelloId = "";
            failPending("Lost connection to mimiclip");
            if (queued.length > 0)
                scheduleCommandReconnect();

            return ;
        }
        commandBackoffMs = 250;
        transportError("");
        commandHelloId = requestId("hello");
        write(commandSocket, {
            "id": commandHelloId,
            "op": "hello",
            "params": {
                "protocolVersion": protocolVersion,
                "client": "quickshell"
            }
        });
    }

    function handleWatchConnection(connected) {
        if (!connected) {
            watchReady = false;
            watchHelloId = "";
            watchRequestId = "";
            scheduleWatchReconnect();
            return ;
        }
        watchBackoffMs = 250;
        transportError("");
        watchHelloId = requestId("watch-hello");
        write(watchSocket, {
            "id": watchHelloId,
            "op": "hello",
            "params": {
                "protocolVersion": protocolVersion,
                "client": "quickshell"
            }
        });
    }

    function handleCommandLine(line) {
        const message = parse(line);
        if (!message)
            return ;

        if (message.id === commandHelloId) {
            commandHelloId = "";
            if (!message.ok) {
                transportError(protocolFailure(message));
                commandSocket.connected = false;
                return ;
            }
            commandReady = true;
            transportError("");
            flushQueue();
            return ;
        }
        const request = pending[message.id];
        if (request === undefined)
            return ;

        const nextPending = Object.assign({
        }, pending);
        delete nextPending[message.id];
        pending = nextPending;
        if (!message.ok) {
            failed(request.operation, failureMessage(message), request.context);
            return ;
        }
        succeeded(request.operation, message.result || {
        }, request.context);
    }

    function handleWatchLine(line) {
        const message = parse(line);
        if (!message)
            return ;

        if (message.id === watchHelloId) {
            watchHelloId = "";
            if (!message.ok) {
                transportError(protocolFailure(message));
                watchSocket.connected = false;
                return ;
            }
            watchRequestId = requestId("watch");
            write(watchSocket, {
                "id": watchRequestId,
                "op": "watch",
                "params": {
                }
            });
            return ;
        }
        if (message.id === watchRequestId) {
            if (!message.ok) {
                transportError(failureMessage(message));
                watchSocket.connected = false;
                return ;
            }
            watchReady = true;
            transportError("");
            return ;
        }
        if (message.event !== undefined)
            eventReceived(message);

    }

    function parse(line) {
        try {
            return JSON.parse(line);
        } catch (parseError) {
            transportError("mimiclip sent an invalid response");
            return null;
        }
    }

    function failureMessage(message) {
        const detail = message.error || {
        };
        return detail.message || "mimiclip rejected the request";
    }

    function protocolFailure(message) {
        const detail = message.error || {
        };
        if (detail.code === "incompatible_protocol")
            return "mimiclip protocol version is incompatible";

        return detail.message || "mimiclip handshake failed";
    }

    function failPending(message) {
        const requests = pending;
        pending = {
        };
        for (const id of Object.keys(requests)) {
            const request = requests[id];
            failed(request.operation, message, request.context);
        }
    }

    function scheduleCommandReconnect() {
        if (commandRetry.running)
            return ;

        commandRetry.interval = commandBackoffMs;
        commandRetry.start();
        commandBackoffMs = Math.min(commandBackoffMs * 2, 10000);
    }

    function scheduleWatchReconnect() {
        if (watchRetry.running)
            return ;

        watchRetry.interval = watchBackoffMs;
        watchRetry.start();
        watchBackoffMs = Math.min(watchBackoffMs * 2, 10000);
    }

    commandSocket: Socket {
        path: client.socketPath
        connected: false
        onConnectedChanged: client.handleCommandConnection(connected)
        onError: (errorCode) => {
            client.transportError("Cannot connect to mimiclip");
            if (client.queued.length > 0)
                client.scheduleCommandReconnect();

        }

        parser: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                return client.handleCommandLine(data);
            }
        }

    }

    watchSocket: Socket {
        path: client.socketPath
        connected: false
        onConnectedChanged: client.handleWatchConnection(connected)
        onError: (errorCode) => {
            client.transportError("Cannot connect to mimiclip");
            client.scheduleWatchReconnect();
        }

        parser: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                return client.handleWatchLine(data);
            }
        }

    }

    commandRetry: Timer {
        repeat: false
        onTriggered: client.ensureCommandConnected()
    }

    watchRetry: Timer {
        repeat: false
        onTriggered: {
            if (!client.watchSocket.connected)
                client.watchSocket.connected = true;

        }
    }

    Component.onCompleted: client.start()

}
