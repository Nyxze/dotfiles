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

**Settled, 2026-09-17: the mark is an orca.** Mascot and logo are one system —
the logo is a detail lifted from the mascot, never a second drawing. The form
is pixel art, which is the only one of the five approaches tried that is
designed small rather than reduced onto small.

The colour is the whole difficulty and it has an answer. An orca is black and
this desktop is black, so the body cannot be its real colour. It takes `line`,
with the belly and the eye patch in `text-primary` and the outline in
`bg-deep`. That reads as the animal at every size and, more importantly, leaves
the accent unspent — a mascot painted in the brand colour is a mascot that has
borrowed the one thing the palette reserves for meaning. The accent is then
free for a single detail, and the source's row of jaw dots is where it belongs.

A silhouette is generated from shapes and snapped onto the grid, not typed cell
by cell. The proportions of an animal cannot be guessed a character at a time,
and a body drawn as a wedge rather than a barrel reads as a fish every time.

`abyss` is the name candidate, and it comes off the reference itself rather
than from a list. Free on this machine.

**What the terminal asked of it, 2026-09-16.** The mark has a first real
surface: a watermark behind the terminal, bottom right, bounded and faint. That
settles two things the ticket left open.

The size range is 16 px to roughly 400 px, which is what decides the form. A
mark that survives 1-bit at favicon size is a monogram or a glyph, never a
wordmark — so the wordmark, if there is one, sits beside the mark rather than
being it, and the watermark can carry either.

The geometry is already fixed by the rest of the language and does not need
inventing: cuts at 45 degrees, no curve anywhere, the one exception being a
switch's pill which does not apply to a mark. Whatever the logo is, it is built
from straight edges and chamfers.

The mark must mean something. `DESIGN.md` rules out serial numbers and
microtext by name — a deliberately unreadable string is noise on a desktop
someone works in — and a watermark is exactly where that temptation lands.

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
