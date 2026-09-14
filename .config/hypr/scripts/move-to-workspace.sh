#!/bin/bash

get_workspaces() {
    hyprctl workspaces -j | jq -r '.[] | "\(.id): \(.name) [\(.windows) window(s)]"' | sort -n
}

get_destinations() {
    echo "1: 1"
    echo "2: 2"
    echo "3: 3"
    echo "4: 4"
    echo "5: 5"
    echo "6: 6"
    echo "7: 7"
    echo "8: 8"
    echo "9: 9"
    echo "Laptop: Laptop"
}

SOURCE=$(get_workspaces | rofi -dmenu -p "Select workspace to move")
[[ -z "$SOURCE" ]] && exit

source_id=$(echo "$SOURCE" | cut -d: -f1)

DEST=$(get_destinations | rofi -dmenu -p "Move workspace $source_id to...")
[[ -z "$DEST" ]] && exit

dest_id=$(echo "$DEST" | cut -d: -f1)

windows=$(hyprctl clients -j | jq -r --arg id "$source_id" '.[] | select(.workspace.id == ($id | tonumber)) | .address')

for win in $windows; do
    hyprctl dispatch movetoworkspace "$dest_id,$win"
done

notify-send "Workspace moved" "Moved workspace $source_id → $dest_id"