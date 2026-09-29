# endfield

Quickshell panels for Hyprland, on the endfield palette.

waybar remains the status bar. This holds what a status bar cannot do: panels
with real layout and interaction, and the notification daemon.

It owns `org.freedesktop.Notifications`, so swaync must stay masked — see
AGENTS.md.

It also replaces both tray applets, suppressed by `.config/autostart/`:

- **blueman-applet.** BlueZ loses its pairing agent with it. Devices already
  paired connect from the panel; pairing a new one that asks for a PIN needs
  `bluetoothctl` or `blueman-manager` started by hand.
- **nm-applet.** Saved connections are system-owned so they reconnect without a
  secret agent, and new passphrases go in through the panel. VPN and 802.1X
  prompts are what is lost — use `nmcli` for those.

## Panels

| Panel   | Contents            | Opens with                                 |
| ------- | ------------------- | ------------------------------------------ |
| Sidebar | Quick settings      | `SUPER+D`, or right-click the waybar clock |
| Toasts  | Live notifications  | appear on their own                        |

Escape closes whichever panel has focus. A panel opens on the screen that has
focus, below the bar, and is only as tall as its content.

The sidebar keeps the clock, battery, quick toggles and the two volume sliders
permanently on screen; everything else is a page behind a chevron.

| Page          | Holds                                              |
| ------------- | -------------------------------------------------- |
| notifications | the feed, newest first — the resting page          |
| network       | wired link, wi-fi list, connect / forget, passphrase entry |
| output        | sinks, and a slider per playing application        |
| input         | sources, and what is currently recording           |
| bluetooth     | adapter power, scan, paired devices with battery   |
| calendar      | month grid                                         |
| power         | TLP mode, and lock / suspend / log out / reboot / off |

Jump straight to one:

```bash
qs -c endfield ipc call sidebar page bluetooth
```

## Running

Started with the session from `.config/hypr/init.lua`.

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
