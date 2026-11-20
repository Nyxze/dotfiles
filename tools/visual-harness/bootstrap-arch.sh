#!/usr/bin/env bash
# Run interactively inside a disposable Arch VM, never on the host.
set -euo pipefail
if ! systemd-detect-virt --vm --quiet; then
    echo "Refusing to install on a non-VM machine" >&2
    exit 2
fi
if [[ ! -f /etc/arch-release ]]; then
    echo "Arch Linux guest required" >&2
    exit 2
fi
echo "Installing minimal components for visual scenes in this Arch VM."
echo "This does not deploy dotfiles, select a Hyprland build, or start a session."
sudo pacman -Syu --needed --     git python python-pillow hyprland rofi nautilus ghostty     grim quickshell papirus-icon-theme     noto-fonts noto-fonts-emoji ttf-jetbrains-mono-nerd ttf-noto-nerd
echo "Done. Provision a compatible Hyprland Lua session and deploy the selected dotfiles."
