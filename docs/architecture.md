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

The Mint installer builds Quickshell for the user from the tagged v0.1.0 source
when it is absent. It requires Qt 6.6 or newer and reports an actionable error
when the enabled Mint repositories are older. The source build disables Wayland
and Hyprland support while retaining X11 and i3 IPC support.

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
