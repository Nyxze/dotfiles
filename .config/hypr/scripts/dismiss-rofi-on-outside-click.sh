#!/usr/bin/env bash

set -euo pipefail

# Layer-shell surfaces do not receive outside-click events. Hyprland sees every
# click, so compare its pointer position with the transient surface bounds.
rects=$(hyprctl layers -j | jq -r '
    .. | objects
    | select(.namespace? == "rofi" or .namespace? == "endfield-shortcut-help")
    | select(.pid? and .x? and .y? and .w? and .h?)
    | [.namespace, .pid, .x, .y, .w, .h] | @tsv
')

[[ -n $rects ]] || exit 0

read -r cursor_x cursor_y < <(hyprctl cursorpos -j | jq -r '[.x, .y] | @tsv')

declare -A rofi_pids=()
declare -i dismiss_shortcuts=0
while IFS=$'\t' read -r surface pid x y width height; do
    if [[ $surface == "rofi" ]]; then
        rofi_pids["$pid"]=1
    else
        dismiss_shortcuts=1
    fi

    if ((cursor_x >= x && cursor_x < x + width && cursor_y >= y && cursor_y < y + height)); then
        exit 0
    fi
done <<<"$rects"

for pid in "${!rofi_pids[@]}"; do
    kill -TERM "$pid" 2>/dev/null || true
done

if ((dismiss_shortcuts)); then
    qs -c endfield ipc call shortcuts close
fi
