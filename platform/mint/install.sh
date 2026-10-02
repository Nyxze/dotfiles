#!/usr/bin/env bash
set -euo pipefail

platform_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$platform_dir/packages/terminal.sh"
source "$platform_dir/packages/desktop.sh"
export PATH="$HOME/.local/bin:$PATH"
progress_step=0
progress_total=4

if [ ! -r /etc/os-release ]; then
    echo "This installer supports Linux Mint only." >&2
    exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release
if [ "${ID,,}" != linuxmint ]; then
    echo "This installer supports Linux Mint only." >&2
    exit 1
fi

show_progress() {
    local label="$1"
    local filled empty index bar=""

    progress_step=$((progress_step + 1))
    filled=$((progress_step * 24 / progress_total))
    empty=$((24 - filled))

    for ((index = 0; index < filled; index++)); do bar+='#'; done
    for ((index = 0; index < empty; index++)); do bar+='.'; done

    printf '\n[%d/%d] [%s] %s\n' "$progress_step" "$progress_total" "$bar" "$label"
}

apt_install_available() {
    local package
    local available=()
    for package in "$@"; do
        if apt-cache show "$package" >/dev/null 2>&1; then
            available+=("$package")
        else
            echo "! package unavailable in this Mint release: $package" >&2
        fi
    done
    [ "${#available[@]}" -eq 0 ] || sudo apt-get install --yes "${available[@]}"
}

show_progress "Installing APT packages"
sudo apt-get update
apt_install_available "${TERMINAL_APT_PACKAGES[@]}" "${DESKTOP_APT_PACKAGES[@]}"

install_nix() {
    local nix_profile=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

    if [ ! -r "$nix_profile" ]; then
        curl --proto '=https' --tlsv1.2 -fsSL https://nixos.org/nix/install | sh -s -- --daemon
    fi

    # shellcheck disable=SC1090
    source "$nix_profile"
}

install_quickshell() {
    local architecture
    local quickshell_flake='git+https://github.com/quickshell-mirror/quickshell?ref=v0.1.0'

    case "$(uname -m)" in
        x86_64) architecture=x86_64-linux ;;
        aarch64) architecture=aarch64-linux ;;
        *)
            echo "Unsupported architecture for Quickshell through Nix: $(uname -m)" >&2
            return 1
            ;;
    esac

    if [ -x "$HOME/.nix-profile/bin/qs" ]; then
        return 0
    fi

    nix --extra-experimental-features 'nix-command flakes' profile install \
        "${quickshell_flake}#packages.${architecture}.default"
}

show_progress "Installing Nix"
install_nix
show_progress "Installing Quickshell 0.1.0"
install_quickshell

show_progress "Installing development tool managers"
if ! command -v mise >/dev/null; then
    curl https://mise.run | sh
fi
if ! command -v uv >/dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Mint's own desktop components remain authoritative. In particular, do not
# replace its display manager, notification daemon, panel, tray, or theme.
