#!/usr/bin/env bash
set -euo pipefail

clients=$(hyprctl clients -j)
active=$(hyprctl activewindow -j | jq -r '.address // empty')
workspace=$(jq -r --arg address "$active" \
    '.[] | select(.address == $address and (.floating | not)) | .workspace.id' \
    <<<"$clients")

[ -n "$workspace" ] || exit 0

group_size=$(jq -r --arg address "$active" \
    '.[] | select(.address == $address) | .grouped | length' \
    <<<"$clients")

if [ "$group_size" -gt 1 ]; then
    hyprctl dispatch moveoutofgroup >/dev/null
    exit 0
fi

if [ "$group_size" -eq 1 ]; then
    hyprctl dispatch togglegroup >/dev/null
    exit 0
fi

read -r ax ay aw ah < <(
    jq -r --arg address "$active" \
        '.[] | select(.address == $address) | [.at[0], .at[1], .size[0], .size[1]] | @tsv' \
        <<<"$clients"
)

target=$(jq -r --arg address "$active" --argjson workspace "$workspace" \
    --argjson ax "$ax" --argjson ay "$ay" --argjson aw "$aw" --argjson ah "$ah" '
        [
            .[]
            | select(
                .address != $address
                and .workspace.id == $workspace
                and (.floating | not)
                and (.grouped | length) > 0
            )
            | . + {
                distance:
                    (((.at[0] + .size[0] / 2) - ($ax + $aw / 2)) | pow(.; 2))
                    + (((.at[1] + .size[1] / 2) - ($ay + $ah / 2)) | pow(.; 2))
            }
        ]
        | sort_by(.distance)
        | first.address // empty
    ' <<<"$clients")

if [ -z "$target" ]; then
    hyprctl dispatch togglegroup >/dev/null
    exit 0
fi

read -r tx ty tw th < <(
    jq -r --arg address "$target" \
        '.[] | select(.address == $address) | [.at[0], .at[1], .size[0], .size[1]] | @tsv' \
        <<<"$clients"
)

dx=$((tx + tw / 2 - ax - aw / 2))
dy=$((ty + th / 2 - ay - ah / 2))

if [ $((dx < 0 ? -dx : dx)) -ge $((dy < 0 ? -dy : dy)) ]; then
    [ "$dx" -lt 0 ] && direction=l || direction=r
else
    [ "$dy" -lt 0 ] && direction=u || direction=d
fi

hyprctl dispatch moveintogroup "$direction" >/dev/null
