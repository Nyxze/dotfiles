#!/usr/bin/env bash
set -euo pipefail

clients=$(hyprctl clients -j)
workspace=$(hyprctl activeworkspace -j | jq -r '.id')
active=$(hyprctl activewindow -j | jq -r '.address // empty')

mapfile -t windows < <(
    jq -r --argjson workspace "$workspace" \
        '.[] | select(.mapped and (.floating | not) and .workspace.id == $workspace) | .address' \
        <<<"$clients"
)

[ "${#windows[@]}" -gt 1 ] || exit 0

active_is_tiled=0
for address in "${windows[@]}"; do
    [ "$address" = "$active" ] && active_is_tiled=1
done
[ "$active_is_tiled" -eq 1 ] || exit 0

group_size() {
    hyprctl clients -j | jq -r --arg address "$1" \
        '.[] | select(.address == $address) | .grouped | length'
}

focus() {
    hyprctl dispatch focuswindow "address:$1" >/dev/null
}

move_into_group() {
    local address=$1 target=$2 direction
    direction=$(direction_to "$address" "$target")
    focus "$address"
    hyprctl dispatch moveintogroup "$direction" >/dev/null

    hyprctl clients -j | jq -e --arg address "$address" --arg target "$target" \
        '.[] | select(.address == $address) | .grouped | index($target)' >/dev/null
}

direction_to() {
    local source=$1 target=$2
    local sx sy sw sh tx ty tw th dx dy
    local state
    state=$(hyprctl clients -j)

    read -r sx sy sw sh < <(
        jq -r --arg address "$source" \
            '.[] | select(.address == $address) | [.at[0], .at[1], .size[0], .size[1]] | @tsv' \
            <<<"$state"
    )
    read -r tx ty tw th < <(
        jq -r --arg address "$target" \
            '.[] | select(.address == $address) | [.at[0], .at[1], .size[0], .size[1]] | @tsv' \
            <<<"$state"
    )

    dx=$((tx + tw / 2 - sx - sw / 2))
    dy=$((ty + th / 2 - sy - sh / 2))

    if [ $((dx < 0 ? -dx : dx)) -ge $((dy < 0 ? -dy : dy)) ]; then
        [ "$dx" -lt 0 ] && printf 'l\n' || printf 'r\n'
        return
    fi

    [ "$dy" -lt 0 ] && printf 'u\n' || printf 'd\n'
}

dissolve_groups() {
    local address size
    for address in "${windows[@]}"; do
        size=$(group_size "$address")
        [ "$size" -gt 0 ] || continue
        focus "$address"
        if [ "$size" -eq 1 ]; then
            hyprctl dispatch togglegroup >/dev/null
        else
            hyprctl dispatch moveoutofgroup >/dev/null
        fi
    done
}

active_group_size=$(group_size "$active")
if [ "$active_group_size" -eq "${#windows[@]}" ]; then
    hyprctl dispatch moveoutofgroup >/dev/null
    hyprctl dispatch layoutmsg "movetoroot active" >/dev/null

    clients=$(hyprctl clients -j)
    active_x=$(jq -r --arg address "$active" '.[] | select(.address == $address) | .at[0]' <<<"$clients")
    support_x=$(jq -r --arg address "$active" --argjson workspace "$workspace" \
        '[.[] | select(.mapped and (.floating | not) and .workspace.id == $workspace and .address != $address) | .at[0]] | min' \
        <<<"$clients")

    if [ "$active_x" -gt "$support_x" ]; then
        hyprctl dispatch layoutmsg swapsplit >/dev/null
    fi

    hyprctl dispatch layoutmsg "splitratio 1.3 exact" >/dev/null
    exit 0
fi

dissolve_groups

seed=
for address in "${windows[@]}"; do
    [ "$address" = "$active" ] && continue
    seed=$address
    break
done
focus "$seed"
hyprctl dispatch togglegroup >/dev/null

for address in "${windows[@]}"; do
    [ "$address" = "$seed" ] && continue
    [ "$address" = "$active" ] && continue
    move_into_group "$address" "$seed"
done

move_into_group "$active" "$seed"
