# Working on these dotfiles

Arch Linux + Hyprland desktop, kept here so a new machine can be brought up to
the same state. Twenty-odd application configs under `.config/`, the personal
scripts under `.local/scripts/`, and the provisioning under `scripts/`.

## The repository is the source of truth

`~/.config/hypr`, `~/.config/waybar`, `~/.config/quickshell` and the rest are
real directories, not symlinks, so an edit here reaches nothing until it is
copied across.

```bash
./deploy                 # every tracked app, plus ~/.local/scripts and the icon theme
./deploy hypr waybar     # just these
./sync-files nwg-look    # the other way round
```

**Hand edits belong in this repository and go out through `deploy`.**
A few paths belong to root rather than to `~`, so `deploy` cannot reach them at
all. Those go out through their own script, which needs `sudo` and therefore a
terminal:

```bash
./scripts/install-system.sh              # the SDDM greeter theme and its drop-in
./scripts/install-system.sh --stage-only # regenerate the derived files, no root
```

`sync-files` runs the other way and is for capturing what an application wrote
on its own — nwg-look, qt5ct, Thunar, VS Code, the GTK bookmarks Nautilus
writes.

Both directions delete, and both refuse to run while the other side holds a
change they would destroy, naming the files. `--force` overrides. A copy
preserves the source timestamp, so an edit made on the other side within the
same second is indistinguishable by clock — that case is reported rather than
guessed at, which is why the guard sometimes asks about a file you believe is
settled.

A few applications own their configuration directory apart from a handful of
files — VS Code buries its settings under gigabytes of history, opencode's sits
beside a `node_modules`. Those are listed in the `SCOPED` table at the top of
both scripts, which names the paths that move; nothing else in the directory is
touched and neither side deletes. Adding an application there is the way to
track one file out of a directory you do not want.

`AGENTS.md`, `DESIGN.md`, `README.md`, `TODO.md` and `CLAUDE.md` are working
documents, not configuration, so neither direction touches them: they are never
copied onto the machine, and never deleted from here because the machine has no
copy. Anything else named like documentation has to be added to that list by
hand — `SKILL.md` deliberately is not on it, because a skill's markdown is its
payload rather than a note about it.

Either way, **verify against the live copy**. A test that reads the repository
is testing nothing.

## Skills and agents work the same way, through their own pair

`prompts/` holds each skill and agent once, and every provider gets a copy of
it — no symlink, so the same rule applies: an edit here reaches no tool until
it is copied across.

```bash
./scripts/install.sh                 # every provider
./scripts/install.sh claude-code     # just this one
./prompts/capture.sh                 # the other way round
```

`capture.sh` is for what a tool wrote on its own: skill-creator writes new
skills straight into the directory it scans. Both directions delete and both
carry the same guard as `deploy`, so neither overwrites what the other side has
not replayed.

Which directory each provider scans lives in `prompts/providers.sh`, and both
scripts read it — adding a provider is one entry there, not a new script.

A provider that reads a different format gets a translation instead of a copy,
listed in the `ADAPTERS` table beside it: opencode's agents are one, since
`tools` is an allowlist there and `model: sonnet` resolves to an empty model
rather than being rejected. An adapted destination is generated — `capture.sh`
skips it and an edit made there is lost on the next install.

## Reloading after a change

| What            | How                                                   |
| --------------- | ----------------------------------------------------- |
| Hyprland        | `hyprctl reload`                                      |
| waybar          | `~/.config/hypr/scripts/refresh.sh` (kills and relaunches waybar and rofi) |
| Quickshell      | it watches its own directory; restart `qs` for a clean slate |
| Backdrop shaders | `./scripts/build-shaders.sh` first — QML loads the compiled `.qsb`, so an edited `.frag` alone changes nothing and says nothing |
| GTK / Qt themes | log out — `nwg-look` and `qt5ct`/`qt6ct` write on exit |
| SDDM greeter    | `preview -c sddm-greeter-qt6 -o shot.png -- sddm-greeter-qt6 --test-mode --theme system/sddm/themes/endfield` — the `-c` is not optional, the greeter opens full-screen wherever it likes and focus alone will not move it. The real one only restarts with the session |
| Nautilus        | `nautilus -q` first — it is D-Bus activated, so a plain relaunch reuses the running process and its old CSS |

Hyprland uses `hyprland.lua` and `require` modules. `hyprctl reload` re-reads
them, so a keybind or monitor change lands immediately. Verify with
`hyprctl binds -j` / `hyprctl monitors -j` rather than by eye. Switching from
the legacy parser requires a new session; reload cannot switch parsers.

Runtime commands use `hyprctl dispatch 'hl.dsp.…'` or `hyprctl eval 'hl.…'`.
`hyprctl keyword` and legacy dispatcher strings do not work in Lua sessions.
The hand-maintained display rules are in `displays.lua`; `monitors.lua` is
nwg-displays output and is deliberately not loaded.

## What lives where

```
.config/            one directory per application, mirroring ~/.config
.local/scripts/     personal scripts on PATH
prompts/            skills and agents, once, for every provider
prompts/adapters/   translations for providers that read another format
system/             root-owned configuration, mirroring / rather than ~
scripts/rice        packages and system state a fresh machine needs
scripts/install.sh  copies prompts/ out to the providers
scripts/install-system.sh  copies system/ out, under sudo
scripts/build-shaders.sh   compiles the backdrop's GLSL into the .qsb Qt6 reads
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

`endfield` is defined in several syntaxes that share nothing:
`.config/theme/endfield.{css,conf,lua,rasi}`, `.config/ghostty/themes/endfield`,
`.config/yazi/theme.toml`, the Qt color schemes, and `Theme.qml` in the Quickshell config. A colour changed
in one has to be changed in all of them. Hyprland uses the Lua palette;
Hyprlock still uses the Hyprlang `.conf` palette.

GTK is the awkward one, and the two versions do not behave alike. GTK4 resolves
the libadwaita colour names at runtime, so `.config/gtk-4.0/gtk.css` redefines
them and every GTK4 application follows. GTK3's Adwaita is compiled from SCSS
down to literal hex, so redefining a name there reaches nothing and
`.config/gtk-3.0/gtk.css` has to restate each surface as a real rule — which
also means it is pinned to Adwaita's internal selectors and worth re-checking
after a GTK3 upgrade. This asymmetry is why the file manager is Nautilus.

**There is no GTK3 theme named `Adwaita-dark`.** The dark one is the built-in
`Adwaita` plus `gtk-application-prefer-dark-theme`. Naming the variant directly
does not fail loudly: GTK3 cannot resolve it, falls back to light Adwaita, and
drops the dark flag on the way, so applications come up white with only the
user CSS showing through.

The palette is fixed and never derived from the wallpaper.

`.config/theme/DESIGN.md` carries the rest of the interface language — the
measured textures, the corner geometry, and what each engine can actually
express. The traits are subtle enough that estimating them by eye lands an
order of magnitude off, which is why the numbers are written down.

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
