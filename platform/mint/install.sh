#!/usr/bin/env bash
set -euo pipefail

platform_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$platform_dir/packages/terminal.sh"
source "$platform_dir/packages/desktop.sh"
export PATH="$HOME/.local/bin:$PATH"
progress_step=0
progress_total=7

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

install_shell_environment() {
    local zsh_path current_shell

    if [ ! -d "$HOME/.oh-my-zsh/.git" ]; then
        if [ -e "$HOME/.oh-my-zsh" ]; then
            echo "Cannot install Oh My Zsh: $HOME/.oh-my-zsh exists but is not a Git checkout." >&2
            return 1
        fi
        git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
    fi

    zsh_path=$(command -v zsh)
    current_shell=$(getent passwd "$USER" | cut -d: -f7)
    if [ "$current_shell" != "$zsh_path" ]; then
        sudo chsh -s "$zsh_path" "$USER"
    fi
}

show_progress "Configuring Zsh and Tmux workflow"
install_shell_environment

show_progress "Installing workstation applications"
bash "$platform_dir/install-applications.sh"

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
    local quickshell_version='0.3.1'
    local quickshell_flake="$platform_dir/quickshell"

    case "$(uname -m)" in
        x86_64) architecture=x86_64-linux ;;
        aarch64) architecture=aarch64-linux ;;
        *)
            echo "Unsupported architecture for Quickshell through Nix: $(uname -m)" >&2
            return 1
            ;;
    esac

    if [ -x "$HOME/.nix-profile/bin/qs" ]; then
        local current_version
        current_version=$("$HOME/.nix-profile/bin/qs" --version | awk 'NR == 1 { print $2 }')
        if [ "$current_version" = "$quickshell_version" ] \
            && grep -Fq nixGLIntel "$(readlink -f "$HOME/.nix-profile/bin/qs")"; then
            return 0
        fi

        nix --extra-experimental-features 'nix-command flakes' profile remove quickshell
    fi

    nix --extra-experimental-features 'nix-command flakes' profile install \
        --impure --no-write-lock-file \
        "${quickshell_flake}#packages.${architecture}.default"
}

install_extra_applications() {
    local yazi_keyring=/usr/share/keyrings/yazi-keyring.gpg
    local yazi_source=/etc/apt/sources.list.d/yazi.list
    local yazi_repository='deb [signed-by=/usr/share/keyrings/yazi-keyring.gpg] https://yazi-rs.github.io/builds/ stable main'
    local packages=()

    if ! command -v yazi >/dev/null; then
        curl -fsSL https://yazi-rs.github.io/builds/yazi-keyring.gpg | sudo tee "$yazi_keyring" >/dev/null
        printf '%s\n' "$yazi_repository" | sudo tee "$yazi_source" >/dev/null
        packages+=(yazi)
    fi

    if ! command -v ghostty >/dev/null; then
        if ! grep -Rqs 'mkasberg/ghostty-ubuntu' /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null; then
            sudo add-apt-repository --yes ppa:mkasberg/ghostty-ubuntu
        fi
        packages+=(ghostty)
    fi

    [ "${#packages[@]}" -eq 0 ] && return 0

    sudo apt-get update
    sudo apt-get install --yes "${packages[@]}"
}

show_progress "Installing Nix"
install_nix
show_progress "Installing Quickshell 0.3.1"
install_quickshell

show_progress "Installing Ghostty and Yazi"
install_extra_applications

show_progress "Installing development tool managers"
if ! command -v mise >/dev/null; then
    curl https://mise.run | sh
fi
if ! command -v uv >/dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Mint's own desktop components remain authoritative. In particular, do not
# replace its display manager, notification daemon, panel, tray, or theme.
