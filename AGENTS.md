# Working on these dotfiles

This repository supports Arch/Hyprland and Linux Mint/Xfce/i3 from a shared
base. User files are copied into real directories rather than symlinked.

## Layers and deployment

`home/common/` contains configuration shared by both systems, including the
GTK4 application theme used by Nautilus. `home/arch-hyprland/` contains
Hyprland, Waybar, nwg, GTK3/Qt, and Wayland-only Endfield files.
`home/mint-xfce/` contains i3, Thunar fallback actions, and X11/i3 Endfield
backends. A profile overlays common files at the same relative path.

```bash
./apply-config
./apply-config --profile arch-hyprland hypr waybar
./apply-config --profile mint-xfce i3 quickshell
./capture-config --profile mint-xfce Thunar
```

`apply-config` detects `arch-hyprland` for Arch and `mint-xfce` for Linux Mint unless
`--profile` is supplied. It writes only files present in the layers. The state
file under `$XDG_STATE_HOME/dotfiles/deployed-files/` records files previously
created by each profile, so cleanup cannot delete application-owned files in
Code, Xfce, Thunar, or other configuration directories. Both deployment and
capture retain their timestamp/checksum overwrite guard; `--force` is the
explicit override.

`AGENTS.md`, `DESIGN.md`, `README.md`, `TODO.md`, `CLAUDE.md`, PDFs, and
`icon-theme.cache` are documentation or generated artifacts and are not
deployed. Verify changes against the live copy after deployment.

## Provisioning

`install.sh` detects the host distribution. Arch provisioning is in
`platform/arch/` and keeps the root-owned SDDM theme in `system/`; only Arch
runs `scripts/install-system.sh`. Mint provisioning is in `platform/mint/`,
uses APT, and leaves Mint's display manager and Xfce/GTK3 desktop theme
untouched. GTK4 application styling is shared so Nautilus looks the same on
both platforms.

Mint keeps Xfce as the fallback desktop. Do not deploy Xfce-wide settings,
panels, applet overrides, GTK3/Qt desktop overrides, or notification ownership
there. GTK4 application overrides are allowed in `home/common/`. i3 supplies
window-management bindings; Xfce retains its panel, tray, NetworkManager
applet, Blueman, audio controls, update tools, and settings.

The Mint desktop has two workspace layouts. Workspace 0, reached with Super+0,
keeps the native Mint/Xfce panel content (menu, launchers, window list, and
tray); placing this panel at the top is acceptable. Workspaces 1–5 should
match the Arch/Hyprland desktop as closely as X11/i3 allows: workspace
controls at the top left, the tray at the top right, and no Mint panel or tray
at the bottom. Switching workspaces must switch the whole layout reliably.
Keep the native Xfce capabilities available when the i3 integration stops.

## Endfield

Read `home/common/.config/quickshell/endfield/AGENTS.md` before changing common
Endfield components. Keep components independent from compositor APIs. Profile
backends own `Panel.qml`, focused-screen resolution, display handling, session
actions, workspace overview, and notification ownership.

Arch uses layer-shell, Hyprland IPC, Wayland previews, custom lock, and
Endfield notifications. Mint uses X11 panels and `Quickshell.I3`, has no
Wayland imports, uses `xflock4`, opens Xfce display settings, and leaves
`xfce4-notifyd` as the notification server. Endfield must remain optional on
Mint: stopping it cannot remove a core Xfce capability.

`tlp-ctl` and `clipboard-copy` live in `home/common/.local/scripts`. The latter
uses `wl-copy` in Wayland sessions and `xclip` in X11 sessions; tmux uses it
instead of calling a compositor clipboard tool directly.

## Reloading and validation

| Target | Command |
| --- | --- |
| Hyprland | `hyprctl reload` |
| i3 | `i3-msg reload` |
| Waybar | `~/.config/hypr/scripts/refresh.sh` |
| Quickshell | restart `qs -c endfield` for a clean session |
| Backdrop shaders | `./scripts/build-shaders.sh` |
| SDDM greeter | `./scripts/install-system.sh --stage-only` then preview on Arch |

The Quickshell files are copied, not live-linked. Deploy before testing. Test
Mint with its own session and ensure i3 navigation, Xfce panel/tray, network,
Bluetooth, audio, lock/logout, clipboard fallback, and Quickshell all work.
