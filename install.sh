#!/usr/bin/env bash
# Install the complete workstation for the detected Linux distribution.
set -euo pipefail

repository_url=https://github.com/Nyxze/dotfiles.git
install_dir="$HOME/stuff/dotfiles"
progress_step=0
progress_total=4

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
        linuxmint) printf '%s\n' mint ;;
        *)
            echo "Unsupported distribution: ${PRETTY_NAME:-$ID}." >&2
            return 1
            ;;
    esac
}

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

bootstrap_repository() {
    local platform="$1"
    local repository_present=0

    case "$platform" in
        arch)
            if ! command -v git >/dev/null; then
                sudo pacman -Syu --needed --noconfirm git
            fi
            ;;
        mint)
            if ! command -v git >/dev/null; then
                sudo apt-get update
                sudo apt-get install --yes git
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
        if [ -n "$(git -C "$install_dir" status --porcelain)" ]; then
            echo "Cannot update dotfiles: $install_dir has local changes." >&2
            return 1
        fi

        git -C "$install_dir" pull --ff-only
    fi

    exec "$install_dir/install.sh"
}

platform=$(detect_platform)
if [ "$platform" = arch ]; then
    progress_total=5
fi
script_path=${BASH_SOURCE[0]-}
repo_root=""
if [ -n "$script_path" ] && [ -f "$script_path" ]; then
    repo_root=$(cd "$(dirname "$script_path")" && pwd)
fi

if [ -z "$repo_root" ] || [ ! -d "$repo_root/.git" ] \
    || [ ! -x "$repo_root/platform/$platform/install.sh" ]; then
    bootstrap_repository "$platform"
fi

show_progress "Provisioning $platform packages"
platform_status=0
if "$repo_root/platform/$platform/install.sh"; then
    :
else
    platform_status=$?
fi

# Installing this repository makes it authoritative on a new workstation.
show_progress "Applying home configuration"
"$repo_root/apply-config" --force
show_progress "Installing skills and agents"
"$repo_root/scripts/install.sh" --force

if [ "$platform_status" -ne 0 ]; then
    echo "Platform provisioning failed after configuration was applied." >&2
    exit "$platform_status"
fi

export PATH="$HOME/.local/bin:$PATH"
show_progress "Installing development toolchains"
mise install
uv python install

if [ "$platform" = arch ]; then
    show_progress "Installing system configuration"
    "$repo_root/scripts/install-system.sh"
fi
