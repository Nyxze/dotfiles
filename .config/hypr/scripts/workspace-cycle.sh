#!/usr/bin/env bash
set -euo pipefail

target=${1:?workspace is required}
current=$(hyprctl activeworkspace -j | jq -r '.name')

if [ "$current" != "$target" ]; then
    hyprctl dispatch workspace "$target" >/dev/null
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

hyprctl dispatch focuswindow "address:$next" >/dev/null
