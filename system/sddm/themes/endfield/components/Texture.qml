import QtQuick

// Tiled overlay for the grid or hatch material, generated and FFT-verified
// into 9x9 PNGs alongside the palette rather than redrawn per engine. Lay it
// over a plate's own fill; the source pixels are white at a tuned alpha so the
// underlying colour still shows through.
//
// The PNGs are copied into the theme at install time. The greeter runs as its
// own user with no home of its own, so a path through $HOME reaches nothing.
//
// Qt.resolvedUrl, and not a bare relative string: a computed URL is resolved
// against whichever file instantiated the component, so the same path loaded
// from a sibling component and from the theme root lands in two different
// directories. Resolving here pins it to this file.
Image {
    property string kind: "grid"

    anchors.fill: parent
    source: Qt.resolvedUrl("../textures/" + kind + ".png")
    fillMode: Image.Tile
    smooth: false
    mipmap: false
}
