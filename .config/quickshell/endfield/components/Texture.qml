import ".."
import Quickshell
import QtQuick

// Tiled overlay for the grid or hatch material, generated and FFT-verified
// into 9x9 PNGs at ~/.config/theme/ (see DESIGN.md) rather than redrawn per
// engine. Lay it over a plate's own fill; the source pixels are white at a
// tuned alpha so the underlying colour still shows through.
Image {
    id: texture

    // "grid": orthogonal, near-invisible, meant for large grounds.
    // "hatch": diagonal, stronger, meant for contained plates — spread over
    // a large ground it stops reading as material and reads as a filter.
    // "hatch-dark": the same diagonal in the deepest surface instead of the
    // lightest, for plates filled with the accent, where a light hatch has
    // nothing to darken.
    property string kind: "grid"

    anchors.fill: parent
    // A relative path here resolves through Quickshell's virtual qs:/ import
    // space, not the real filesystem, and silently fails past the config
    // root ("Cannot open: qrc:/qs-blackhole"). The theme lives one directory
    // above quickshell/, outside that space, so this needs a real file: URL.
    source: "file://" + Quickshell.env("HOME") + "/.config/theme/" + kind + ".png"
    fillMode: Image.Tile
    smooth: false
    mipmap: false
}
