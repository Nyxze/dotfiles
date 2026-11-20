# 04 — Quickshell sidebar, Waybar and system controls

## Existing ownership

- home/common/.config/quickshell/endfield/Theme.qml — semantic tokens and typography
- home/common/.config/quickshell/endfield/panels/Sidebar.qml — pages, focus, layout
- home/common/.config/quickshell/endfield/components/ — reusable primitives
- home/common/.config/quickshell/endfield/widgets/ — specific controls
- home/arch-hyprland/.config/quickshell/endfield/ — Wayland/Hyprland backend
- home/mint-xfce/.config/quickshell/endfield/ — X11/i3 backend
- home/common/.config/theme/endfield.css — Waybar/GTK
- tools/visual-harness/scenes/sidebar.json — Arch capture scenario

## Visual target

A compact top bar and a 380px right sidebar with consistent header, rail and rows. Subordinate metadata must be legible. Use the existing selected-fill / active-rail / focus-border grammar; do not turn every tile yellow. Keep the quick settings operational, not decorative.

## Iterations

1. Ensure a running Quickshell process in guest; capture closed/open/notifications states.
2. Verify panel containment and screen choice at 1600x900 and 1920x1080; no clipping below top bar.
3. Tune text scale, rail spacing, active tile and muted label contrast.
4. Tune network, audio, notifications, power pages one at a time. Validate backend ownership: PipeWire, NetworkManager, BlueZ and TLP must not have parallel competing readers or daemons.
5. Confirm keyboard and mouse traversal use the same Cursor highlight; Esc backs out of a page then closes the sidebar.
6. Verify no missing glyphs at the final rendered sizes. Capture both closed and open controls to catch state regressions.

## Functional acceptance

Opening and closing leaves no stuck overlay; keyboard focus is recoverable; network and Bluetooth controls do not invoke actual host services; Mint retains Xfce notification ownership. Always validate at least one long page and one empty page.

## Exclusions

No replacement of native session services purely for visual consistency; no persistent dashboard or wallpaper animation.
