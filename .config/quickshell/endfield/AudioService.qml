pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import QtQuick

// Single view onto PipeWire for the whole shell. Holds the one object tracker:
// without it the `audio` property of a node never populates.
Singleton {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.config/quickshell/endfield/scripts/sink-availability.sh"

    property bool probing: false
    // Node name -> available. A name absent from the map is assumed available.
    property var sinkAvailability: ({})

    // Devices and streams differ only by isStream: a sink with isStream is an
    // application feeding a sink, not a piece of hardware.
    readonly property var rawSinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property var rawSources: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio)

    // PipeWire empties nodes.values for a frame while it rebinds; cache the
    // last non-empty list so the device rows do not flash blank.
    property var cachedSinks: []
    property var cachedSources: []

    onRawSinksChanged: if (rawSinks.length > 0)
        cachedSinks = rawSinks
    onRawSourcesChanged: if (rawSources.length > 0)
        cachedSources = rawSources

    // A sink stays in the graph whether or not its port is plugged in, so an
    // idle HDMI output or an unplugged jack has to be filtered out here.
    readonly property var sinks: {
        const base = rawSinks.length > 0 ? rawSinks : cachedSinks;
        return base.filter(n => sinkAvailability[n.name] !== false);
    }
    readonly property var sources: rawSources.length > 0 ? rawSources : cachedSources

    readonly property var streams: Pipewire.nodes.values.filter(n => n.isSink && n.isStream && n.audio)
    readonly property var recorders: Pipewire.nodes.values.filter(n => !n.isSink && n.isStream && n.audio && n.name !== "quickshell")

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    // PipeWire descriptions repeat the same boilerplate on every port of the
    // machine, which says nothing about which one is being picked.
    function cleanLabel(text) {
        return text
            .replace(/^(sof-\S+|built-?in audio)\s+/i, "")
            .replace(/\s+(analog|digital) stereo$/i, "")
            .replace(/\s+(output|input)$/i, "")
            .replace(/microphones/i, "Microphone")
            .trim();
    }

    function label(node) {
        if (!node)
            return "";
        return cleanLabel(node.nickname || node.description || node.name);
    }

    function volumeOf(node) {
        return node && node.audio ? node.audio.volume : 0;
    }

    function mutedOf(node) {
        return node && node.audio ? node.audio.muted : false;
    }

    function setVolume(node, level) {
        if (node && node.audio)
            node.audio.volume = level;
    }

    function toggleMute(node) {
        if (node && node.audio)
            node.audio.muted = !node.audio.muted;
    }

    function setSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setSource(node) {
        Pipewire.preferredDefaultAudioSource = node;
    }

    function sinkGlyph(node) {
        if (!node)
            return "󰓃";
        const text = `${node.name} ${node.description} ${node.nickname}`.toLowerCase();
        if (/headphone|headset|earbud|earphone|airpod/.test(text))
            return "󰋋";
        if (/bluetooth/.test(text))
            return "󰂯";
        if (/hdmi|display/.test(text))
            return "󰍹";
        return "󰓃";
    }

    function sourceGlyph(node) {
        if (!node)
            return "󰍬";
        const text = `${node.name} ${node.description} ${node.nickname}`.toLowerCase();
        if (/headset/.test(text))
            return "󰋋";
        if (/bluetooth/.test(text))
            return "󰂯";
        if (/webcam|camera/.test(text))
            return "󰄀";
        return "󰍬";
    }

    // Spotify (and a few others) name their stream "audio-src" instead of the
    // app name; fall back to the one MPRIS player nothing else already claims.
    function streamLabel(node) {
        if (!node)
            return "";
        const cleaned = cleanLabel(node.description || node.name);
        if (cleaned.toLowerCase() !== "audio-src")
            return cleaned;

        const otherLabels = streams.filter(s => s !== node).map(s => cleanLabel(s.description || s.name));
        const candidates = Mpris.players.values.filter(p => !otherLabels.includes(p.identity));
        return candidates.length === 1 ? candidates[0].identity : cleaned;
    }

    // Scanning ports is only worth its cost while a page is showing the list.
    function setProbing(on) {
        probing = on;
    }

    PwObjectTracker {
        objects: Pipewire.nodes.values
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.probing
        triggeredOnStart: true
        onTriggered: probe.running = true
    }

    Process {
        id: probe
        command: [root.script]

        stdout: StdioCollector {
            onStreamFinished: {
                const map = {};
                for (const line of this.text.trim().split("\n")) {
                    if (!line)
                        continue;
                    const [name, flag] = line.split("\t");
                    map[name] = flag === "1";
                }
                root.sinkAvailability = map;
            }
        }
    }
}
