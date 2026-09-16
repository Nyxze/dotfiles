#!/bin/bash
# Repository -> the system paths ./deploy cannot reach because root owns them.
# Right now that is the SDDM greeter theme and the drop-in that selects it.
#
# The theme is not a second copy of the interface language. Everything in it
# that already exists in the quickshell config is derived from that config
# here, so a colour or a plate shape keeps one definition instead of two.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHELL_DIR="$ROOT/.config/quickshell/endfield"
PALETTE="$ROOT/.config/theme"
THEME="$ROOT/system/sddm/themes/endfield"
DEST=/usr/share/sddm/themes/endfield
QSB=/usr/lib/qt6/bin/qsb

# Components that are already pure QtQuick and carry no Quickshell import, so
# they cross over untouched.
SHARED=(ChamferedRect BannerPlate IconButton ListRow LoginWell)

# The materials those components load.
TEXTURES=(hatch hatch-dark)

# The orbit backdrop travels as a directory rather than as a list of parts: its
# components, its shaders and its baked clouds only mean anything together, and
# the greeter and the shell's lock screen mount the same one.
BACKDROP=(Orbit Globe PointCloud Trail)
BACKDROP_SHADERS=(globe cloud)

stage() {
    # Theme.qml is a Quickshell singleton, and the greeter has no such module.
    # Dropping the import and swapping the base type is the whole difference —
    # small enough to derive, which is the point: a hand-kept copy would be the
    # eighth place the palette lives and the first one to fall behind.
    sed -e '/^import Quickshell$/d' -e 's/^Singleton {$/QtObject {/' \
        "$SHELL_DIR/Theme.qml" > "$THEME/Theme.qml"

    if grep -q 'Quickshell' "$THEME/Theme.qml"; then
        echo "✗ Theme.qml still imports Quickshell — the shell's copy was reformatted." >&2
        exit 1
    fi

    local name
    for name in "${SHARED[@]}"; do
        install -Dm644 "$SHELL_DIR/components/$name.qml" "$THEME/components/$name.qml"
    done
    for name in "${TEXTURES[@]}"; do
        install -Dm644 "$PALETTE/$name.png" "$THEME/textures/$name.png"
    done

    # The terrain still is one composed image rather than a tile, so it travels
    # on its own rather than through the texture list. It is what the greeter
    # falls back to when the shaders do not load.
    install -Dm644 "$PALETTE/greeter.png" "$THEME/ground.png"

    # Qt6 dropped inline GLSL, so the shaders go through qsb into a .qsb before
    # QML will load them. This is the one artefact here that needs a compiler
    # rather than a rasteriser, and qsb is not on PATH.
    if [ ! -x "$QSB" ]; then
        echo "✗ $QSB is missing — install qt6-shadertools." >&2
        exit 1
    fi
    for name in "${BACKDROP[@]}"; do
        install -Dm644 "$SHELL_DIR/backdrop/$name.qml" "$THEME/backdrop/$name.qml"
    done

    local shader stage
    for shader in "${BACKDROP_SHADERS[@]}"; do
        for stage in vert frag; do
            install -Dm644 "$SHELL_DIR/backdrop/shaders/$shader.$stage" \
                "$THEME/backdrop/shaders/$shader.$stage"
            "$QSB" --qt6 -o "$THEME/backdrop/shaders/$shader.$stage.qsb" \
                "$SHELL_DIR/backdrop/shaders/$shader.$stage" >/dev/null
        done
    done

    # The clouds are baked by .config/theme/pointcloud.py from raw XYZ dumps
    # that do not live in this repository. What ships is the texture pair.
    install -dm755 "$THEME/backdrop/clouds"
    install -m644 "$PALETTE"/clouds/*.png "$THEME/backdrop/clouds/"

    echo "✓ staged ${#SHARED[@]} component(s), ${#TEXTURES[@]} texture(s)," \
         "${#BACKDROP[@]} backdrop part(s), $(( ${#BACKDROP_SHADERS[@]} * 2 )) shader(s)," \
         "the ground and the palette"
}

publish() {
    sudo install -dm755 "$DEST"
    sudo rsync -a --delete "$THEME/" "$DEST/"
    sudo install -Dm644 "$ROOT/system/sddm/sddm.conf.d/10-endfield.conf" \
        /etc/sddm.conf.d/10-endfield.conf
    echo "✓ installed to $DEST, selected in /etc/sddm.conf.d/10-endfield.conf"
}

stage
case "${1-}" in
    --stage-only) ;;
    "") publish ;;
    *) echo "usage: $0 [--stage-only]" >&2; exit 2 ;;
esac
