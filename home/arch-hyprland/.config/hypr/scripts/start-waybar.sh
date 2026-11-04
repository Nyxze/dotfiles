#!/usr/bin/env bash
set -euo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
exec waybar --config "$config_home/waybar/config" --style "$config_home/waybar/style.css"
