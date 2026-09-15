# Working on these dotfiles

Arch Linux + Hyprland desktop, kept here so a new machine can be brought up to
the same state. Twenty-odd application configs under `.config/`, the personal
scripts under `.local/scripts/`, and the provisioning under `scripts/`.

## The repository is a snapshot, not the live config

`~/.config/hypr`, `~/.config/waybar`, `~/.config/quickshell` and the rest are
real directories, not symlinks into this repository. Editing a file here
changes nothing on the running machine until it is copied across, and every
application keeps reading its own copy.

**`sync-files` only runs one way: live → repo, with `--delete`.**

```bash
./sync-files                 # every tracked app, plus ~/.local/scripts
./sync-files hypr waybar     # just these
./sync-files scripts         # just ~/.local/scripts
```

So a repo-only edit is not merely inert, it is at risk: the next `sync-files`
overwrites it with whatever is live. There is no push script — the machine is
the source of truth and this repository is the capture.

Two workable orders, and it matters which one you pick:

- Change the live file, test it, then `./sync-files <app>` to capture it.
- Or change it here, copy it across yourself, test, and do not let a
  `sync-files` run in between.

Either way, **verify against the live copy**. A test that reads the repo is
testing nothing.

## Reloading after a change

| What            | How                                                   |
| --------------- | ----------------------------------------------------- |
| Hyprland        | `hyprctl reload`                                      |
| waybar          | `~/.config/hypr/scripts/refresh.sh` (kills and relaunches waybar and rofi) |
| Quickshell      | it watches its own directory; restart `qs` for a clean slate |
| GTK / Qt themes | log out — `nwg-look` and `qt5ct`/`qt6ct` write on exit |

`hyprctl reload` re-reads every `source =` file, so a keybind or monitor change
lands immediately. Verify with `hyprctl binds -j` / `hyprctl monitors -j`
rather than by eye.

## What lives where

```
.config/            one directory per application, mirroring ~/.config
.local/scripts/     personal scripts on PATH
prompts/            Claude Code skills and agents; scripts/install.sh deploys them
scripts/rice        packages and system state a fresh machine needs
scripts/install.sh  deploys prompts/ into ~/.claude and ~/.opencode
TODO.md             parked tasks — see the convention in its header
```

`scripts/rice` is where a new dependency belongs. A package the config needs at
runtime but never installs is the failure that only shows up on the next
machine.

## The Quickshell config has its own guide

`.config/quickshell/endfield/AGENTS.md` covers the shell: its layout, the
keyboard cursor, the service quirks, and how to screenshot a panel without
taking over the screen. Read it before touching anything under that directory.

## The palette

`endfield` is defined five times over, in five syntaxes that share nothing:
`.config/theme/endfield.{css,conf,rasi}`, `.config/ghostty/themes/endfield`, and
`Theme.qml` in the Quickshell config. A colour changed in one has to be changed
in all of them.

The palette is fixed and never derived from the wallpaper.

## Testing on a live desktop

The second monitor is usually in use, so render into an off-screen output
instead of taking over a real one — `.config/quickshell/endfield/AGENTS.md`
documents the full recipe, including the `hyprctl reload` that has to follow
removing the output.

Two traps that cost time:

- **Check the screen is not locked before capturing or injecting keys.**
  `pgrep -x hyprlock` — a lock screen covers everything, so captures show it
  instead of the panel, and synthetic keystrokes land in its password field.
- **Anything needing a TTY goes through tmux**, not a tool call. `sudo`,
  `ssh`, an interactive prompt: the non-interactive shell has no terminal and
  they fail there even when run by hand.
