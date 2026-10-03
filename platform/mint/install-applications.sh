#!/usr/bin/env bash
set -euo pipefail

install_root_file_if_changed() {
    local source="$1" destination="$2" mode="${3:-0644}"

    if sudo test -r "$destination" && sudo cmp -s "$source" "$destination"; then
        return 0
    fi

    sudo install -D -o root -g root -m "$mode" "$source" "$destination"
}

setup_vscode_repository() {
    local temporary key source
    temporary=$(mktemp -d)
    key="$temporary/microsoft.gpg"
    source="$temporary/vscode.sources"

    curl --proto '=https' --tlsv1.2 -fsSL https://packages.microsoft.com/keys/microsoft.asc |
        gpg --dearmor >"$key"

    cat >"$source" <<'EOF'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64 arm64 armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF

    install_root_file_if_changed "$key" /usr/share/keyrings/microsoft.gpg
    install_root_file_if_changed "$source" /etc/apt/sources.list.d/vscode.sources
    rm -rf "$temporary"
}

setup_brave_repository() {
    local temporary key source
    temporary=$(mktemp -d)
    key="$temporary/brave-browser-archive-keyring.gpg"
    source="$temporary/brave-browser-release.sources"

    curl --proto '=https' --tlsv1.2 -fsSL \
        https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg \
        -o "$key"
    curl --proto '=https' --tlsv1.2 -fsSL \
        https://brave-browser-apt-release.s3.brave.com/brave-browser.sources \
        -o "$source"

    install_root_file_if_changed "$key" /usr/share/keyrings/brave-browser-archive-keyring.gpg
    install_root_file_if_changed "$source" /etc/apt/sources.list.d/brave-browser-release.sources
    rm -rf "$temporary"
}

install_vendor_apt_applications() {
    sudo apt-get install --yes ca-certificates curl fontconfig gnupg wget xz-utils
    setup_vscode_repository
    setup_brave_repository
    sudo apt-get update
    sudo apt-get install --yes code brave-browser
}

write_postman_desktop_entry() {
    local binary="$1"
    local applications="$HOME/.local/share/applications"
    local desktop="$applications/postman.desktop"

    mkdir -p "$applications"
    cat >"$desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Postman
Exec=$binary %U
Icon=/opt/Postman/app/resources/app/assets/icon.png
Terminal=false
Categories=Development;
EOF
}

postman_binary() {
    local candidate
    for candidate in /opt/Postman/Postman /opt/Postman/app/Postman; do
        if [ -x "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

install_postman() {
    local architecture url temporary binary

    if binary=$(postman_binary); then
        sudo ln -sfn "$binary" /usr/local/bin/postman
        write_postman_desktop_entry "$binary"
        return 0
    fi

    if command -v postman >/dev/null 2>&1; then
        return 0
    fi

    case "$(uname -m)" in
        x86_64) url=https://dl.pstmn.io/download/latest/linux64 ;;
        aarch64|arm64) url=https://dl.pstmn.io/download/latest/linux_arm64 ;;
        *)
            echo "Unsupported architecture for Postman: $(uname -m)" >&2
            return 1
            ;;
    esac

    temporary=$(mktemp -d)
    curl --proto '=https' --tlsv1.2 -fL "$url" -o "$temporary/postman.tar.gz"
    tar -xzf "$temporary/postman.tar.gz" -C "$temporary"

    if [ ! -d "$temporary/Postman" ]; then
        echo "Postman archive did not contain the expected Postman directory." >&2
        rm -rf "$temporary"
        return 1
    fi

    sudo rm -rf /opt/Postman
    sudo cp -a "$temporary/Postman" /opt/Postman
    rm -rf "$temporary"

    binary=$(postman_binary) || {
        echo "Postman installed but its executable could not be found." >&2
        return 1
    }

    sudo ln -sfn "$binary" /usr/local/bin/postman
    write_postman_desktop_entry "$binary"
}

install_chatgpt() {
    local architecture package temporary

    if dpkg-query -W -f='${Status}' chatgpt 2>/dev/null | grep -q '^install ok installed$'; then
        sudo apt-get update
        sudo apt-get install --yes chatgpt
        return 0
    fi

    case "$(dpkg --print-architecture)" in
        amd64) architecture=amd64 ;;
        arm64) architecture=arm64 ;;
        *)
            echo "Unsupported architecture for ChatGPT: $(dpkg --print-architecture)" >&2
            return 1
            ;;
    esac

    temporary=$(mktemp -d)
    package="$temporary/chatgpt_${architecture}.deb"
    curl --proto '=https' --tlsv1.2 -fL \
        "https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_${architecture}.deb" \
        -o "$package"
    sudo apt-get install --yes "$package"
    rm -rf "$temporary"
}

install_nerd_fonts() {
    local version='3.5.1'
    local font_root="$HOME/.local/share/fonts/NerdFonts"
    local temporary changed=0 family archive target

    mkdir -p "$font_root"
    temporary=$(mktemp -d)

    for family in JetBrainsMono Noto; do
        target="$font_root/$family"
        if [ -r "$target/.version" ] && [ "$(cat "$target/.version")" = "$version" ]; then
            continue
        fi

        archive="$temporary/$family.tar.xz"
        curl --proto '=https' --tlsv1.2 -fL             "https://github.com/ryanoasis/nerd-fonts/releases/download/v$version/$family.tar.xz"             -o "$archive"

        rm -rf "$target"
        mkdir -p "$target"
        tar -xJf "$archive" -C "$target"
        printf '%s\n' "$version" >"$target/.version"
        changed=1
    done

    rm -rf "$temporary"
    if [ "$changed" -eq 1 ]; then
        fc-cache -f "$font_root"
    fi
}

install_vendor_apt_applications
install_postman
install_chatgpt
install_nerd_fonts
