pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire

// Single view onto PipeWire for the whole shell. Holds the one object tracker:
// without it the `audio` property of a node never populates.
Singleton {
    id: root

    // Devices and streams differ only by isStream: a sink with isStream is an
    // application feeding a sink, not a piece of hardware.
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property var sources: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isSink && n.isStream && n.audio)
    readonly property var recorders: Pipewire.nodes.values.filter(n => !n.isSink && n.isStream && n.audio && n.name !== "quickshell")

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    function label(node) {
        if (!node)
            return "";
        return node.description || node.nickname || node.name;
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

    PwObjectTracker {
        objects: Pipewire.nodes.values
    }
}
