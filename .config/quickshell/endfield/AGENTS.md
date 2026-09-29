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
  NetworkService.qml     singleton: NetworkManager, plus everything nmcli and
                         iproute2 have to supply
  BluetoothService.qml   singleton: BlueZ, grouped device lists, audio hand-off
  Cursor.qml             singleton: the one highlight, shared by mouse and keyboard
  scripts/               what no QML binding exposes — nmcli and pactl, nothing else
  components/            reusable and domain-free — Panel, Tile, SliderRow, ListRow,
                         Section, IconButton, LevelSlider, PasswordField, LoginWell,
                         PageHeader, ToggleSwitch, PillRow, DetailGrid, LevelRow,
                         KeyCatcher, ChamferedRect, BannerPlate, Texture
  backdrop/              the orbit scene and its shaders, mounted by the lock
                         screen and staged into the greeter
  widgets/               always-visible pieces of the sidebar head
  pages/                 the swappable detail views
  panels/                composes the above into a surface — the sidebar, the
                         toasts, and the lock screen
```

The backdrop is GLSL, and QML loads the compiled `.qsb` rather than the source.
`../../../scripts/build-shaders.sh` is what puts an edited shader in front of
the engine; nothing warns when it has not been run, the old binary just keeps
rendering. The greeter then copies those artefacts rather than compiling its
own, so both surfaces run the same build.

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
QuickTiles        network · bluetooth · dnd · tlp
VolumeControls    output · input · live input meter
─────────────
PageRail          one icon per page, so the set is visible without hunting
<page>            notifications by default
```

`Sidebar.pages` is the single list the rail and the heading both read;
`Sidebar.page` names the visible one. The rail selects outright, while
`openPage(name)` toggles so a tile chevron is both the way in and the way back.
Escape leaves the page before it leaves the panel, and closing resets to
notifications.

Every page also has a keybind in `.config/hypr/keybinds.lua`
(`SUPER+CTRL+{C,A,M,W,B,D,P}`), and waybar's gear button toggles the panel.

## The cursor

One highlight on screen, written by the mouse and the keyboard alike. An
interactive component paints itself from `Cursor.item === <its own root>`, never
from its own `containsMouse`, and claims the cursor when hovered. That is what
keeps a single row lit at any moment, and what lets a hand leaving the mouse
carry on from where the pointer was instead of jumping to the top of the list.

A navigable item declares `navigable: true` and a `navActivate()`; optionally
`navRemove()` when it has something to delete, and `navAdjust(step)` when Left
and Right should change a value rather than move sideways.

```
j / ↓      next row          Enter / Space   activate
k / ↑      previous row      x               delete (forget a network, a device)
h / ←      adjust, or move within the row    Tab / Shift+Tab   previous/next page
l / →                                        Escape            back, then close
```

`Sidebar` walks the item tree to find the stops, because nothing about that tree
is reactive — there is no binding to hang the list off, so it is rescanned on
every move and by a 250 ms timer while the panel is open. Two stops belong to
the same horizontal group when their vertical centres nearly coincide; that is
read from geometry rather than from the parent's type, so a 2x2 tile grid gives
two rows of two while two stacked sliders stay two separate stops.

A list that rebuilds underneath the cursor destroys the item it points at — a
Wi-Fi scan does this every few seconds — so the position is remembered in
`Cursor.index` and restored when the item goes null.

A text field sets `Cursor.editing`, which stands the key handler down so a `j`
typed into a passphrase is a letter and not a move.

## Adding a page

1. `pages/YourPage.qml` — a `ColumnLayout`, no frame of its own; group rows with
   `Section` and use `ListRow` for anything selectable.
2. Add an entry to `Sidebar.pages`, a `Component` wrapper, and a case to the
   `sourceComponent` switch. The switch cannot collapse into the array: an `id`
   does not resolve from inside a property literal, so a `view: somePage` key
   silently leaves the whole array undefined.
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
3. Bind it in `.config/hypr/keybinds.lua` with
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

**Never name a `Panel` member `open`, `close`, `show`, `hide` or `escape`.**
`PanelWindow` inherits `Window`, which already defines the first four; the
override is silently ignored and the call does nothing — a `show(name)` that
looked fine was really calling `Window.show()` and never changed the page.
`escape` is worse and better at once: QML rejects it outright with
`Illegal method name`, so at least it fails loudly. Hence `openPanel`,
`closePanel`, `openPage`, `dismiss`.

**An `OnDemand` layer already has keyboard focus when it maps.** Hyprland grants
it on map, so a panel summoned from a keybind responds to Escape without ever
being clicked — no `Exclusive` prime is needed, and priming would route every
pointer event on every output to that surface for as long as it lasted. Qt still
needs an active-focus target inside the surface, which is what `Panel`'s
`focusTarget` plus a `Qt.callLater` `forceActiveFocus()` provides; reopening does
not restore one on its own.

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

**A `Shape` derives its implicit size from its path's bounding box.** Give
`ChamferedRect` a `borderWidth` and the stroke widens that box, so a plate
sitting in a layout grows by the stroke width every pass — implicit size feeds
the layout, the layout feeds the path — until it fills whatever contains it.
The symptom is a tile that swallows the panel. `ChamferedRect` wraps its Shape
in a plain `Item` for exactly this reason; anything else that reaches for
`QtQuick.Shapes` directly has to do the same.

**Edits to this repository are not live.** Quickshell watches
`~/.config/quickshell/endfield`, a copy rather than a symlink, so nothing here
reaches it until `./deploy quickshell` runs. Deploy before testing, or you will
be reading screenshots of the previous version.

## Testing without taking over the screen

`preview` does this, and encodes every trap below:

```bash
preview -o /tmp/shot.png -- qs -c endfield ipc call sidebar toggle
preview -c org.gnome.Nautilus -o /tmp/shot.png -- nautilus --new-window ~
```

It refuses to run under a lock screen, sets the output mode explicitly, focuses
the output before the command, verifies with `-c` that the window actually
landed there, and removes the output and reloads on the way out even when the
command fails.

Doing it by hand is what the script exists to avoid, but the traps are worth
knowing, because they all cost time before it existed:

- A fresh headless output defaults to 1920x1080 at scale 2, so it is 960x540
  logical and captures at 2x. Set its mode explicitly or every measurement is
  doubled and panels come back clipped.
- The output is named after the ones already there, so a second one is
  `HEADLESS-2`. Resolve the name instead of hardcoding it.
- **Focus decides where a panel opens, not where a window opens.** A launched
  application lands wherever its workspace rules put it, so it has to be moved
  and the move has to be verified. Skipping that is how a panel ends up on a
  monitor someone is using.
- **Run `hyprctl reload` after removing the output**, every time. Removing it
  strands whichever workspace was on it and that workspace's `SUPER+n` bind
  goes dead until the reload reattaches it.
- Check the screen is not locked before capturing or injecting keys
  (`pgrep -x hyprlock`). A lock screen covers every output, so captures show it
  instead of the panel and synthetic keystrokes land in its password field.
- `hyprctl layers` lists panels under `surfaceName`. A panel that does not set
  one appears as `quickshell`, which makes it look absent if you grep for the
  name you expected.

Errors go to the log, not to stdout, once daemonised:

```bash
qs -c endfield                 # foreground: parse errors appear immediately
strings /run/user/1000/quickshell/by-id/*/log.qslog | tail
```

## Tokens

`Theme.qml` is one of eight copies of the endfield palette, alongside
`.config/theme/endfield.{css,conf,lua,rasi}`, `ghostty/themes/endfield` and
`qt{5,6}ct/colors/endfield.conf` — none of those parsers share a syntax. A
colour changed here must be changed in all of them. `.config/theme/DESIGN.md`
holds the language itself: what each token means, the type scale, the spacing
unit, and which surface takes which texture.

Never hardcode a colour, a font size or a margin in a component. Colours come
from the semantic tokens; type comes from a font role assigned whole
(`font: Theme.body`), so a size and its weight cannot drift apart; every margin
and gap is `Theme.space(n)`, which takes the step count on a 4px grid rather
than the pixel value. If `Theme` is missing something, add it there.

Two rules the components hold to and a new one must not break:

- **Three shapes, one accent, no trading.** A fill means *chosen among
  several* (`ListRow.selected`, `PillRow.active`, `NavRow.selected`). A 4px
  rail means *switched on*, independently (`Tile.active`). A 2px border means
  *the cursor is here*, and inverts to `Theme.onAccent` over a filled row.
  A tile is a toggle, not a choice — that is why it takes the rail and not the
  fill.
- **Nothing is rounded, except the switch.** A plate cuts opposite corners
  through `ChamferedRect`; everything else is square. `ToggleSwitch` is the one
  pill, because a bevelled switch reads as a very small button. `Theme` has no
  radius token to reach for — that `height / 2` is deliberate and local.
- **Hover is not a state here.** The shell has one highlight, `Cursor`, and it
  means focus. GTK's hover underline and press bar have no counterpart in this
  tree on purpose.

## Glyphs

Check a codepoint before using it:

```bash
fc-list ":charset=F0200" family | grep -c 'NotoMono Nerd Font'
```

Coverage is necessary and not sufficient. Several Material icons are dense
enough to collapse into a grey lump at the 13–14 px these panels use — the
ethernet port `󰈀` is one. Render a candidate at the real size before committing
to it, and drop the icon rather than ship an unreadable one: a glyph that
carries no information the row does not already state is noise anyway.

## Service quirks found so far

**`UPowerDevice.percentage` is a 0..1 fraction**, not a percentage, despite the
name. Multiply by 100 to display it.

**Pipewire nodes are told apart by two flags, not one.** Output devices are
`isSink && !isStream`; applications playing sound are `isSink && isStream`.
Capture devices and recording streams mirror that with `isSink` false.

**A sink stays in the graph with nothing plugged into it.** PipeWire keeps the
headphone jack and an idle HDMI output selectable, and picking one silently
swallows the sound. Only `pactl` knows a port is unavailable, which is what
`scripts/sink-availability.sh` reports; `AudioService.sinks` filters on it while
`setProbing(true)` is on.

**`Pipewire.nodes.values` empties for a frame while it rebinds.** Bind a list
straight to it and the device rows flash blank. `AudioService` keeps the last
non-empty result and falls back to it.

**Pipewire node properties stay empty without a tracker.** A
`PwObjectTracker { objects: … }` covering the nodes you bind to is what makes
`node.audio.volume` readable at all.

**Never read `PwNode.properties`.** It is invalid until the node is bound, and
reading it while capture streams come and go can destabilise Quickshell's
Pipewire service. Tell node kinds apart with `isSink`/`isStream` instead, which
is what `AudioService` does.

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

Port *availability* is the one piece of that already handled — see
`scripts/sink-availability.sh`. Anything that has to write a profile still
belongs to pavucontrol, which is what waybar's right-click still opens.

`Bluetooth` by contrast is complete: adapters expose `enabled` and
`discovering`, devices expose `connected`, `paired`, `battery` and the
connect/disconnect/pair/forget methods.

## Bluetooth quirks

**BlueZ reports a state change a beat after the request**, so a row clicked to
connect reads "paired" again for a second. `BluetoothService.pending` holds what
was asked for until the real state agrees, or 20 s pass and it gives up — a
request BlueZ silently drops must not leave a row stuck.

**A headset's PipeWire sink appears a second or two after BlueZ says it is
connected.** Switching the default output on the connect signal alone finds
nothing, so `BluetoothService` polls `AudioService.sinks` for a name containing
the device address (`:` becomes `_`) eight times at 750 ms before giving up.

## Networking quirks

`Networking` is complete enough to replace nm-applet: `connect`, `disconnect`,
`forget`, `connectWithPsk`, `known`, `signalStrength`, and a `connectionFailed`
signal whose `NoSecrets` reason is the cue to ask for a passphrase.

**`Networking.devices` is empty for about a second after startup.** Everything
reading it has to tolerate a null device rather than assume one.

**`signalStrength` is a 0..1 fraction**, not the 0..100 NetworkManager reports.

**No scan happens until `WifiDevice.scannerEnabled` is set.** Until then the
network list holds only the one currently connected. Turn it on when the page
appears and off when it goes, so a closed panel is not scanning on battery.

**`NetworkDevice.address` is the MAC address**, not the IP. There is no IP
property at all; `NetworkService` parses `ip -j -4 addr show` for it.

**Band and DNS need nmcli, not the binding.** Neither is exposed in QML, so
`scripts/net-ctl.sh` owns them: `status` reports the band in use, the pinned
band, the bands the access point actually answers on, and which DNS provider the
active profile points at; `band` and `dns` write them back. Both write paths
reassociate the Wi-Fi, which takes seconds — `NetworkService.busy` is what keeps
the pills from being clicked again meanwhile.

**Never offer a band the access point does not answer on.** Pinning one drops
the connection with nothing to reassociate to, which is why the script
intersects with a cached scan rather than listing 2.4/5/6 unconditionally.

**The details probes are gated on `setPolling`.** Throughput reads
`/sys/class/net/<if>/statistics`, latency shells out to `ping`, and the band and
DNS come from the script — none of it is worth running while the page is closed.
Totals belong to an interface, so they all reset when `interfaceName` changes.

**`NetworkConnectivity` distinguishes `Portal` from `Limited`**, so a captive
portal is detectable without a probe of our own.

**Saved connections here are system-owned** (`psk-flags=0`), so NetworkManager
reconnects without a secret agent, and `connectWithPsk` passes new secrets
inline. Verified by taking the connection down and back up with nm-applet not
running. That is what let nm-applet go; what went with it is the interactive
prompt for VPN and 802.1X secrets, which now needs `nmcli`.
