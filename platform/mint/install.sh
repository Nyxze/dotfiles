#!/usr/bin/env bash
set -euo pipefail

platform_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$platform_dir/packages/terminal.sh"
source "$platform_dir/packages/desktop.sh"

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

sudo apt-get update
apt_install_available "${TERMINAL_APT_PACKAGES[@]}" "${DESKTOP_APT_PACKAGES[@]}" "${QUICKSHELL_BUILD_PACKAGES[@]}"

install_quickshell() {
    command -v qs >/dev/null && return 0

    if ! pkg-config --atleast-version=6.6 Qt6Core; then
        echo "Quickshell needs Qt 6.6 or newer; this Mint release provides $(pkg-config --modversion Qt6Core 2>/dev/null || echo 'no Qt 6')." >&2
        echo "Install a newer Qt 6 toolchain, then rerun this installer." >&2
        return 1
    fi

    local build_dir
    build_dir=$(mktemp -d)
    trap 'rm -rf -- "$build_dir"' RETURN
    git clone --depth 1 --branch v0.1.0 https://github.com/quickshell-mirror/quickshell.git "$build_dir/quickshell"
    cmake -GNinja -S "$build_dir/quickshell" -B "$build_dir/build" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$HOME/.local" \
        -DWAYLAND=OFF \
        -DHYPRLAND=OFF
    cmake --build "$build_dir/build"
    cmake --install "$build_dir/build"
}

install_quickshell

if ! command -v mise >/dev/null; then
    curl https://mise.run | sh
fi
if ! command -v uv >/dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Mint's own desktop components remain authoritative. In particular, do not
# replace its display manager, notification daemon, panel, tray, or theme.
