# TODO

Tasks captured from `## TODO ##` blocks, newest last. Each entry keeps the
request as it was written, so a task still reads correctly once the
conversation that produced it is gone.

Format:

```
## <short title>
<date captured>

<the request, verbatim>

Notes: anything already known — a file it touches, a blocker, a decision left open.
```

---

## System name and visual identity
2026-09-14

> Se crée un logo / identité visuel et choisir un nom de "system" pour faire
> comme omarchy avec leur CLI -> Add exemples

Pick one name for the whole setup and let it carry the CLI, then give it a
logo.

**What the name buys, going by Omarchy.** Every entry point is one prefix, so
the set is discoverable by typing it and hitting tab:

```
omarchy-menu                    the command palette
omarchy-shell <target> <method> IPC into the running shell
omarchy-theme-set <name>        switch theme, rewrite every app's config
omarchy-default-browser firefox one-shot setting
omarchy-launch-config-editor    open a real config file in $EDITOR
omarchy-audio-output-volume     bound to XF86AudioRaiseVolume
```

`ii` does the same with packages rather than commands —
`illogical-impulse-audio`, `-backlight`, `-fonts-themes` — and lucid with
directories: `lucidbar`, `luciddock`, `lucidlock`, `lucidprefs`, `lucidshot`.

**Where we stand.** `endfield` already names the palette
(`.config/theme/endfield.{css,conf,rasi}`, `ghostty/themes/endfield`) and the
Quickshell config (`qs -c endfield`). So either endfield grows into the system
name, or the system takes a new name and endfield stays the palette — worth
deciding before anything is renamed, because the palette name appears in five
files.

**What a prefix would replace today.** Scattered, no shared entry point:

```
qs -c endfield ipc call sidebar page network
~/.config/hypr/scripts/tlp-ctl.sh toggle
~/.config/hypr/scripts/move-to-workspace.sh
scripts/rice
```

**Notes**
- Logo: needs to work as a 1-bit glyph in a bar and at favicon size, not just
  as a large mark. The palette is fixed (near-black, bright yellow, olive).
- Decide whether the prefix wraps the existing scripts or replaces them.
- Nothing here is urgent; renaming touches the palette files, waybar, hypr
  keybinds and the Quickshell config directory at once.

---

## Hyprland workspace context menu
2026-09-15

Hyrland worksapce context menu (right click / shortcut)

Notes: no compositor-side menu exists — Hyprland has no popup primitive, so
this is a Quickshell surface bound to a keybind, and to waybar's
`#workspaces button` right-click for the pointer route. waybar can only run a
command on `on-click-right`, so both routes end at
`qs -c endfield ipc call <target> toggle`.

Open: whether it anchors at the pointer or at the workspace button. A layer
shell surface can be positioned by margins, but nothing reports the pointer
position to a panel — `hyprctl cursorpos` would have to be read at open time.

Reuses: `Panel` (layer-shell, Escape, focused screen), `ListRow` for the
entries, `Cursor` for keyboard navigation. Actions worth having are the ones
`hypr/keybinds.conf` already binds — move window here, rename, switch.
