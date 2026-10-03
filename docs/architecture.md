# Repository architecture

The repository supports two desktop profiles from one shared base:

```text
home/
  common/                   files shared by both desktops
  arch-hyprland/            Hyprland, Waybar, nwg, GTK/Qt overrides
  mint-xfce/                i3, Thunar actions, and X11 Endfield backends
platform/
  arch/                     pacman/AUR provisioning
  mint/                     apt provisioning and Quickshell build
system/                     Arch-only root-owned SDDM configuration
```

## User-file layers

`apply-config` copies `home/common` first and then the selected profile. A profile
file at the same relative path deliberately overlays the common one. It copies
individual files only; application-owned siblings below `~/.config` are never
removed.

The state file at `$XDG_STATE_HOME/dotfiles/deployed-files/<profile>` records
the paths and hashes created by a successful deployment. A later deployment may
remove only paths in that state file, and refuses to remove one that the user or
an application changed unless `--force` is given.

`capture-config` copies a live file back to the source layer that currently wins the
overlay. It keeps the timestamp/checksum guard and never guesses a deletion.

```bash
./apply-config
./apply-config --profile arch-hyprland hypr waybar
./apply-config --profile mint-xfce i3 quickshell
./capture-config --profile mint-xfce Thunar
```

The default profile comes from `/etc/os-release`: `arch` selects
`arch-hyprland`, and `linuxmint` selects `mint-xfce`. `--profile` is intended
for testing a layer without changing the host distribution.

## Platforms

The root `install.sh` bootstraps Git when necessary and dispatches to the
detected platform installer. Arch continues to install its complete Hyprland
desktop and publishes the SDDM theme. Mint installs its terminal and Xfce/i3
dependencies with APT and does not run `scripts/install-system.sh`.

The Mint installer keeps the distribution Qt stack untouched. Quickshell 0.3.1
is provided through a small Nix flake so its newer Qt runtime stays isolated
from APT. The same provisioning pass also installs the required workstation
applications that are not in Mint's default repositories: VS Code and Brave
through their vendor APT repositories, Postman from its vendor Linux bundle,
and ChatGPT from OpenAI's Debian package. The Mint setup also installs the
JetBrains Mono and Noto Nerd Font families used by i3, Ghostty, and terminal
glyphs from the pinned Nerd Fonts release.

Mint also makes Zsh the login shell and installs the user-local Oh My Zsh tree
expected by the shared prompt. This is what makes the common Ghostty/Zsh/Tmux
configuration behave the same way as it does on Arch, including the Ctrl-F
tmux session launcher.

## Desktop boundaries

Arch owns Hyprland, Waybar, nwg utilities, custom GTK/Qt styling, and the
Wayland implementations of Endfield panels, notifications, lock screen,
display handling, workspace previews, and window groups.

Mint leaves Xfce's panel, tray, notification daemon, network applet, Blueman,
audio controls, display settings, lock screen, and display manager untouched.
i3 supplies the shared window-management shortcut contract. Endfield uses X11
panels and i3 IPC there; its workspace overview shows workspace metadata rather
than Wayland previews, and its display page opens the native Xfce settings.

Common Endfield components may use desktop-independent services such as
PipeWire, BlueZ, NetworkManager, Calendar, and the sidebar UI. Backend files
are always profile-owned. Common files do not import Hyprland, Wayland, or call
`hyprctl` or `wl-copy`.
