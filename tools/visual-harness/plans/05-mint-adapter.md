# 05 — Mint Xfce/i3 adaptation (second phase)

The initial executable harness is deliberately Arch/Hyprland only. Do not claim a validated Mint screenshot from the Arch scene runner.

## Current repository boundaries

- Xfce provides session services and fallbacks; i3 handles tiling/window bindings.
- home/mint-xfce/.config/i3/config currently quits xfdesktop and xfce4-panel; some docs describe an earlier native-panel-on-workspace-0 arrangement. **Reconcile actual intended behavior before implementation.**
- Mint uses the X11 Quickshell backend and leaves xfce4-notifyd authoritative.
- Nautilus and Ghostty are configured as preferred applications; Thunar is a fallback.

## Separate harness adapter to design

Build an X11/i3 capture backend that runs wholly in the Mint VM. Preferred validation: dedicated virtual X server (Xvfb/Xephyr) or disposable VM display, not the host DISPLAY. It must launch i3, stage a known workspace, place an application by X11 window class, capture the isolated display (e.g. via ImageMagick import or scrot), clean up and report its own metadata. Do not reuse Hyprland IPC or Wayland screenshots in this adapter.

## Reuse

Keep the shared semantic tokens, Ghostty, Rofi and Nautilus test fixtures identical where possible; use GTK3/Thunar snapshots where behavior differs. Avoid overriding Mint desktop-wide settings, panel ownership, system dialogs or notification daemon merely to imitate Arch.

## Exit conditions

Separate X11 fixture screenshots, keyboard/mouse behavior, reliable i3 workspace selection, desktop fallback still functional, no lingering X11 processes, no modifications to the host session. Do not mark this phase complete until its backend exists and runs in a Mint VM.
