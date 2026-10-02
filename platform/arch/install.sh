#!/usr/bin/env bash
set -euo pipefail

platform_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$platform_dir/packages/terminal.sh"
source "$platform_dir/packages/desktop.sh"

PACMAN_PACKAGES=(
    "${TERMINAL_PACMAN_PACKAGES[@]}"
    "${DESKTOP_PACMAN_PACKAGES[@]}"
)
AUR_PACKAGES=(
    "${TERMINAL_AUR_PACKAGES[@]}"
    "${DESKTOP_AUR_PACKAGES[@]}"
)

missing_packages() {
    local package
    for package in "$@"; do
        pacman -Q "$package" >/dev/null 2>&1 || printf '%s\n' "$package"
    done
}

if [ ! -r /etc/arch-release ]; then
    echo "This installer supports Arch Linux only." >&2
    exit 1
fi

mapfile -t missing_pacman < <(missing_packages "${PACMAN_PACKAGES[@]}")
if [ "${#missing_pacman[@]}" -gt 0 ]; then
    sudo pacman -Syu --needed --noconfirm "${missing_pacman[@]}"
else
    echo "✓ official packages already installed"
fi

if ! command -v yay >/dev/null; then
    yay_build_dir=$(mktemp -d)
    trap 'rm -rf -- "$yay_build_dir"' EXIT
    git clone https://aur.archlinux.org/yay-bin.git "$yay_build_dir/yay-bin"
    (cd "$yay_build_dir/yay-bin" && makepkg -si --needed --noconfirm)
fi

mapfile -t missing_aur < <(missing_packages "${AUR_PACKAGES[@]}")
if [ "${#missing_aur[@]}" -gt 0 ]; then
    yay -S --needed --noconfirm "${missing_aur[@]}"
else
    echo "✓ AUR packages already installed"
fi

# Docker is available on demand but must never be activated at boot.
sudo systemctl disable docker.service docker.socket containerd.service 2>/dev/null || true

# Quickshell owns notifications; prevent the old daemon from reclaiming D-Bus.
systemctl --user mask swaync.service 2>/dev/null || true

gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal ghostty
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal new-tab true
gsettings set org.gnome.desktop.interface gtk-theme Adwaita
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark

# Papirus upgrades restore the default blue folders.
sudo papirus-folders -C grey --theme Papirus-Dark
