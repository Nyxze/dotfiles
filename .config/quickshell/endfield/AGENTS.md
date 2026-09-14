# Working on this Quickshell config

Quickshell shell for Hyprland, holding the widgets waybar cannot express:
panels with real layout, state and interaction. waybar stays the status bar;
anything that needs to be more than text in a tooltip lives here.

## Layout

```
endfield/
  shell.qml              entry point — mounts panels, wires them to IPC, nothing else
  qmldir                 declares the singletons (see the constraint below)
  Theme.qml              singleton: palette, fonts, metrics
  FocusedScreen.qml      singleton: resolves which ShellScreen a panel opens on
  NotificationService.qml  singleton: owns org.freedesktop.Notifications
  AudioService.qml       singleton: the one view onto PipeWire, holds the tracker
  TlpService.qml         singleton: power mode, read and written through tlp-ctl.sh
  components/            reusable and domain-free — Panel, Tile, SliderRow, ListRow,
                         Section, IconButton, LevelSlider
  widgets/               always-visible pieces of the sidebar head
  pages/                 the swappable detail views
  panels/                composes the above into a surface
```

The split that matters: `components/` must stay ignorant of what it displays. A
component that mentions a month, a volume level or a battery belongs in
`widgets/` or `pages/`. When one of those grows a piece a second could use,
move that piece into `components/` and strip whatever tied it to the first.

Anything that talks to a daemon belongs in a singleton, not in the view. A
widget and a page that need the same state must read it from the same service —
two `Process` blocks polling the same command is the failure mode to avoid.

`panels/` should contain almost no markup — a panel arranges widgets and routes
between pages.

## The sidebar

Quick settings, not a stack of cards: a fixed head that never scrolls over a
content region that swaps.

```
SidebarHeader     clock · battery          → calendar / power page
QuickTiles        bluetooth · dnd · tlp · session
VolumeControls    output · input · live input meter
─────────────
<page>            notifications by default, detail pages behind the chevrons
```

`Sidebar.page` names the visible page; `show(name)` toggles, so a chevron is
both the way in and the way back. Closing the panel resets to notifications.

## Adding a page

1. `pages/YourPage.qml` — a `ColumnLayout`, no frame of its own; group rows with
   `Section` and use `ListRow` for anything selectable.
2. Add a case to `Sidebar`'s `sourceComponent` switch, a `Component` wrapper,
   and an entry in `pageTitles`.
3. Give it an entry point: a `Tile` with `expandable: true`, or a `SliderRow`
   chevron.

Reach it directly with `qs -c endfield ipc call sidebar page <name>` — which is
also how to screenshot it without clicking.

## Adding a head widget

Only for state worth keeping on screen permanently. Everything else is a page.
A head widget emits `pageRequested(string)` rather than knowing what the
sidebar does with it.

## Adding a panel

1. `panels/YourPanel.qml` — derive from `Panel`, set `surfaceName`, size and
   anchors, put the content inside.
2. Mount it in `shell.qml` and add an `IpcHandler` with its own `target`.
3. Bind it in `.config/hypr/keybinds.conf` with
   `qs -c endfield ipc call <target> toggle`.

`Panel` already handles layer-shell placement, the frame, Escape to close, and
opening on the focused screen. A panel that re-implements any of that is a bug.

Set `contentHeight` so the frame grows with what is in it, and wrap any list
that can outgrow the screen in a `Flickable`.

## Constraints that cost time to find

**Singletons need `qmldir`, everything else must not be in it.** A directory
with a `qmldir` exposes *only* what that file declares, so implicit resolution
of sibling `.qml` files stops working. This is why the root holds nothing but
`shell.qml` and the two singletons: adding a component there would make it
invisible until it is also declared. Put components in a subdirectory.

**Subdirectories need `import ".."`** to reach the singletons. Each directory is
its own implicit module.

**Never name a `Panel` member `open`, `close`, `show` or `hide`.** `PanelWindow`
inherits `Window`, which already defines them; the override is silently ignored
and the call does nothing. Hence `openPanel` / `closePanel`.

**`Hyprland.focusedMonitor` is unusable.** It is never seeded at startup and
stays null until a focus change happens after Quickshell launches, and
`refreshMonitors()` populates the monitor list without setting the `focused`
flag. `FocusedScreen` shells out to `hyprctl monitors -j` instead.

**`exclusionMode` decides whether a panel collides with the bar.** `Ignore`
makes it disregard waybar's exclusive zone and sit underneath it. `Normal` plus
`exclusiveZone: 0` respects the bar while reserving nothing.

**`qs -c endfield ipc call <target> show` collides with the `ipc show`
subcommand** and prints the target list instead of calling. Use `toggle`, or
call the function something other than `show`.

**A panel cannot work out how much height the bar left it.** Anchoring top only
and capping at `screen.height` overshoots by the bar's exclusive zone. Anchor
top *and* bottom so the compositor reports the real available height in
`panel.height`, size the frame to `min(contentHeight, panel.height)`, and set
`mask: Region { item: frame }` so the unused strip still passes clicks through.

**A `MouseArea` placed straight into a `RowLayout` or `ColumnLayout` is sized by
the layout**, so `anchors.fill: parent` warns and does nothing useful. Wrap the
block in a plain `Item` and put the `MouseArea` inside that.

**`Timer` comes from `QtQuick`.** A singleton that imports only `Quickshell` and
`Quickshell.Io` fails to load with `Timer is not a type`, and the error surfaces
as a chain of unrelated "Type X unavailable" lines up through every singleton.

**Edits to this repository are not live.** Quickshell watches
`~/.config/quickshell/endfield`. Deploy before testing, or you will be reading
screenshots of the previous version.

## Testing without taking over the screen

Hyprland can create an off-screen output to render into:

```bash
hyprctl output create headless                    # appears as HEADLESS-n
hyprctl keyword monitor HEADLESS-1,1920x1080@60,3520x0,1   # match a real screen
hyprctl keyword workspace 6,monitor:HEADLESS-1,default:true
hyprctl dispatch focusmonitor HEADLESS-1          # panels open on the focused screen
qs -c endfield ipc call sidebar toggle
grim -o HEADLESS-1 /tmp/shot.png
hyprctl output remove HEADLESS-1
```

Two traps when reading the result:

- A fresh headless output defaults to 1920x1080 at scale 2, so it is 960x540
  logical and captures at 2x — panels get clipped and every measurement is
  doubled. Set its mode explicitly, as above, before judging a layout.
- `hyprctl layers` lists panels under `surfaceName`. A panel that does not set
  one appears as `quickshell`, which makes it look absent if you grep for the
  name you expected.

Errors go to the log, not to stdout, once daemonised:

```bash
qs -c endfield                 # foreground: parse errors appear immediately
strings /run/user/1000/quickshell/by-id/*/log.qslog | tail
```

## Palette

`Theme.qml` is one of five copies of the endfield palette, alongside
`.config/theme/endfield.{css,conf,rasi}` and `ghostty/themes/endfield` — none of
those parsers share a syntax. A colour changed here must be changed in all of
them.

Never hardcode a colour in a component. If `Theme` is missing a token, add it
there.

## Service quirks found so far

**`UPowerDevice.percentage` is a 0..1 fraction**, not a percentage, despite the
name. Multiply by 100 to display it.

**Pipewire nodes are told apart by two flags, not one.** Output devices are
`isSink && !isStream`; applications playing sound are `isSink && isStream`.
Capture devices and recording streams mirror that with `isSink` false.

**Pipewire node properties stay empty without a tracker.** A
`PwObjectTracker { objects: … }` covering the nodes you bind to is what makes
`node.audio.volume` readable at all.

**`UPower.PowerProfiles` reports nothing on this machine.** It talks to
power-profiles-daemon, and this system runs TLP instead. `tlp-stat -m` reads
the current mode without root; changing it goes through `pkexec` and will
prompt for a password.

## Notifications

This shell owns `org.freedesktop.Notifications`. Only one process on the
session can, so no other notification daemon may run: swaync is masked
(`systemctl --user mask swaync`), which also blocks its D-Bus activation since
its activation file delegates to the systemd unit.

Watch for anything that re-activates a competing daemon. waybar's
`custom/notification` module ran `swaync-client -swb` once per output, which
kept bringing swaync back from the dead even after stopping the unit.

`NotificationService` keeps two lists on purpose. `history` is everything still
tracked; `popups` is the subset currently on screen. A toast timing out leaves
history alone, dismissing removes it from both. A notification that is not
marked `tracked` is destroyed as soon as the signal handler returns.

## What the audio API does not cover

Quickshell's Pipewire binding exposes nodes and links only — `PwNode`,
`PwNodeAudio`, `PwLink`, `PwLinkGroup`, `PwNodePeakMonitor`, `PwObjectTracker`.
There is no card, profile, port or route type. Everything in pavucontrol's
Configuration tab is therefore out of reach through QML and needs `pactl` in a
`Process`:

- switching a Bluetooth headset between A2DP and HFP/HSP,
- turning an HDMI card on so sound can leave through the monitor,
- choosing between the speaker and headphone port of one card.

`Bluetooth` by contrast is complete: adapters expose `enabled` and
`discovering`, devices expose `connected`, `paired`, `battery` and the
connect/disconnect/pair/forget methods.
