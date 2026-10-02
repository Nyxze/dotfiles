#!/bin/bash
# GLSL -> .qsb, in place, for the shell's backdrop.
#
# Qt6 dropped inline GLSL: ShaderEffect loads a compiled .qsb and nothing else,
# so an edited .frag reaches the running shell only once this has been through
# it. Nothing warns when it has not — the old binary keeps working, the change
# simply never happens, and the greeter, which compiles on install, drifts away
# from the shell it is supposed to mirror.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHADERS="$ROOT/home/common/.config/quickshell/endfield/backdrop/shaders"
QSB=/usr/lib/qt6/bin/qsb

if [ ! -x "$QSB" ]; then
    echo "✗ $QSB is missing — install qt6-shadertools." >&2
    exit 1
fi

built=0
for source in "$SHADERS"/*.vert "$SHADERS"/*.frag; do
    [ -e "$source" ] || continue
    "$QSB" --qt6 -o "$source.qsb" "$source" >/dev/null
    built=$((built + 1))
done

echo "✓ compiled $built shader(s) in $SHADERS"
