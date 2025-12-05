#!/bin/bash

# --- Configuration ---
# 1. Internal Monitor ID: This ID should be constant (e.g., eDP-1 for a laptop screen).
INTERNAL_MONITOR="eDP-1" 
# ---------------------

# Get arguments:
# $1: TARGET_MONITOR (Monitor ID to move workspaces to)
# $2: DISABLE_FLAG (e.g., "disable" or "d")
TARGET_MONITOR="$1"
DISABLE_FLAG="$2"

# --- 1. Find the Target Monitor if not explicitly provided (Fallback Logic) ---
if [ -z "$TARGET_MONITOR" ]; then
    # Fallback to the first external monitor ID
    ALL_MONITORS=$(hyprctl monitors | awk '/Monitor/ {print $2}')
    for id in $ALL_MONITORS; do
        if [ "$id" != "$INTERNAL_MONITOR" ]; then
            TARGET_MONITOR="$id"
            break
        fi
    done

    if [ -z "$TARGET_MONITOR" ]; then
        echo "No external monitor found. Exiting." >&2
        exit 0
    fi
fi

# Verify the target monitor is active before proceeding
if ! hyprctl monitors | grep -q "Monitor $TARGET_MONITOR"; then
    echo "Error: Target monitor '$TARGET_MONITOR' is not active." >&2
    exit 1
fi

echo "Starting workspace move to $TARGET_MONITOR."
# --- 2. Move All Active Workspaces ---
# Get a list of all existing workspace IDs, excluding scratchpads (-1)
echo "TARGET MONITOR: $TARGET_MONITOR"
WORKSPACES=$(hyprctl workspaces | awk '/workspace ID/ {if ($3 > 0) print $3}' | sort -n)
echo "WORKSPACE : $WORKSPACES"
for ws_id in $WORKSPACES; do
    # Command: move a specific workspace to the target monitor
    echo "Moving workspace $ws_id... to $TARGET_MONITOR"
    hyprctl dispatch moveworkspacetomonitor "$ws_id" "$TARGET_MONITOR"
done

# --- 4. Conditionally Disable the Internal Monitor ---
if [ "$DISABLE_FLAG" == "disable" ] || [ "$DISABLE_FLAG" == "d" ]; then
    echo "Disabling internal monitor ($INTERNAL_MONITOR)..."
    hyprctl keyword monitor "$INTERNAL_MONITOR", disable
fi

exit 0