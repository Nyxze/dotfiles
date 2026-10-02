#!/usr/bin/env bash
# Install the complete workstation for the detected Linux distribution.
set -euo pipefail

repository_url=https://github.com/Nyxze/dotfiles.git
install_dir="$HOME/stuff/dotfiles"

if [ "$#" -ne 0 ]; then
    echo "usage: $0" >&2
    exit 2
fi

if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    echo "Run this installer as your regular user; it invokes sudo when needed." >&2
    exit 1
fi

detect_platform() {
    if [ ! -r /etc/os-release ]; then
        echo "Cannot identify this Linux distribution: /etc/os-release is missing." >&2
        return 1
    fi

    source /etc/os-release
    case "${ID,,}" in
        arch) printf '%s\n' arch ;;
        *)
            echo "Unsupported distribution: ${PRETTY_NAME:-$ID}." >&2
            return 1
            ;;
    esac
}

bootstrap_repository() {
    local platform="$1"
    local repository_present=0

    case "$platform" in
        arch)
            if ! command -v git >/dev/null; then
                sudo pacman -Syu --needed --noconfirm git
            fi
            ;;
    esac

    if [ -e "$install_dir" ]; then
        if git -C "$install_dir" rev-parse --git-dir >/dev/null 2>&1; then
            repository_present=1
        else
            echo "Cannot clone dotfiles: $install_dir exists and is not a Git repository." >&2
            return 1
        fi
    fi

    if [ "$repository_present" -eq 0 ]; then
        mkdir -p "$(dirname "$install_dir")"
        git clone "$repository_url" "$install_dir"
    else
        echo "✓ repository already present at $install_dir"
    fi

    exec "$install_dir/install.sh"
}

platform=$(detect_platform)
script_path=${BASH_SOURCE[0]-}
repo_root=""
if [ -n "$script_path" ] && [ -f "$script_path" ]; then
    repo_root=$(cd "$(dirname "$script_path")" && pwd)
fi

if [ -z "$repo_root" ] || [ ! -d "$repo_root/.git" ] \
    || [ ! -x "$repo_root/platform/$platform/install.sh" ]; then
    bootstrap_repository "$platform"
fi

"$repo_root/platform/$platform/install.sh"

# Installing this repository makes it authoritative on a new workstation.
"$repo_root/deploy" --force
"$repo_root/scripts/install.sh" --force

mise install
uv python install

"$repo_root/scripts/install-system.sh"
