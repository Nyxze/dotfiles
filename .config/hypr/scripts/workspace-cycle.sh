#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lua-ipc.sh"

target=${1:?workspace is required}
current=$(hyprctl activeworkspace -j | jq -r '.name')

if [ "$current" != "$target" ]; then
    hypr_lua dispatch "hl.dsp.focus({ workspace = $(lua_quote "$target") })"
    exit 0
fi

active=$(hyprctl activewindow -j | jq -r '.address // empty')
mapfile -t windows < <(
    hyprctl clients -j | jq -r --arg workspace "$target" \
        '.[] | select(.mapped and .workspace.name == $workspace) | .address'
)

[ "${#windows[@]}" -gt 1 ] || exit 0

next=${windows[0]}
for i in "${!windows[@]}"; do
    [ "${windows[$i]}" = "$active" ] || continue
    next=${windows[$(( (i + 1) % ${#windows[@]} ))]}
    break
done

hypr_lua dispatch "hl.dsp.focus({ window = $(lua_quote "address:$next") })"
