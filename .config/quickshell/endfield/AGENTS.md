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
  components/            reusable and domain-free — Panel, Card, IconButton, LevelSlider
  widgets/               one subject each: audio, power, calendar
  panels/                composes widgets into a surface
```

The split that matters: `components/` must stay ignorant of what it displays. A
component that mentions a month, a volume level or a battery belongs in
`widgets/`. When a widget grows a piece a second widget could use, move that
piece into `components/` and strip whatever tied it to the first.

`panels/` should contain almost no markup — a panel picks widgets and stacks
them. Logic there is a sign something belongs in a widget.

## Adding a widget

Derive from `Card`, take the title, and put the subject's own state in it.
Children stack vertically; non-visual children (`Process`, `Timer`,
`PwObjectTracker`) can sit alongside the visual ones.

```qml
import ".."
import "../components"
import QtQuick.Layouts

Card {
    title: "Subject"

    RowLayout {
        Layout.fillWidth: true
        // …
    }
}
```

Then add it to a panel's stack. Nothing else to register.

## Adding a panel

1. `panels/YourPanel.qml` — derive from `Panel`, set `surfaceName`, size and
   anchors, stack widgets inside.
2. Mount it in `shell.qml` and add an `IpcHandler` with its own `target`.
3. Bind it in `.config/hypr/keybinds.conf` with
   `qs -c endfield ipc call <target> toggle`.

`Panel` already handles layer-shell placement, the frame, Escape to close, and
opening on the focused screen. A panel that re-implements any of that is a bug.
Wrap the stack in a `Flickable` so it scrolls instead of clipping on a short
screen.

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

## Division of labour with swaync

swaync stays the notification daemon and owns notification history, do-not-
disturb and the media player. Its control centre was trimmed to those when the
sidebar took over toggles and sliders — do not reintroduce a control that
exists on both sides.
