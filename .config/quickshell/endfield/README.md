# endfield

Quickshell panels for Hyprland, on the endfield palette.

waybar remains the status bar. This holds what a status bar cannot do: panels
with real layout and interaction.

## Panels

| Panel   | Contents                  | Opens with                                 |
| ------- | ------------------------- | ------------------------------------------ |
| Sidebar | Power, audio, calendar    | `SUPER+D`, or right-click the waybar clock |

Escape closes whichever panel has focus. A panel opens on the screen that has
focus, below the bar.

## Running

Started with the session from `.config/hypr/init.conf`:

```
exec-once = uwsm app -- qs -c endfield
```

Manually:

```bash
qs -c endfield          # foreground, errors on stdout
qs -c endfield -d       # daemonised
pkill -x qs             # stop
```

`qs` watches its config directory and reloads on save, so no restart is needed
after editing a `.qml` file.

It watches the deployed copy under `~/.config/quickshell/`, not this
repository. Either edit the deployed copy and capture it afterwards with
`./sync-files quickshell`, or edit here and deploy with `./dev-env.sh` — both
from the repo root.

## Requirements

`quickshell` (official repos), Hyprland, and `hyprctl` on `PATH`. The
`HarmonyOS Sans` and `NotoMono Nerd Font` families are expected; both are
already required by the rest of this repo.

## Adding a panel

See `AGENTS.md`.
