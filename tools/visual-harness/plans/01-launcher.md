# 01 — Endfield launcher (first experimental target)

## Why first

A small self-contained overlay gives a fast agent feedback loop without rebuilding the shell. Start with the existing Rofi drun launcher; do not rewrite it in Quickshell until a measured limitation justifies the cost.

## Existing ownership

- home/common/.config/rofi/config.rasi — modes, icon theme, terminal
- home/common/.config/rofi/endfield.rasi — component geometry, states, spacing
- home/common/.config/theme/endfield.rasi — palette
- home/common/.config/theme/rofi-tail.py — selected-row graphic
- home/arch-hyprland/.config/hypr/keybinds.lua — Super+F launch binding (do not modify during first iterations)
- tools/visual-harness/scenes/launcher.json — capture contract

## Visual target

Retain the Endfield vocabulary: dark panel (#111A23), dark search input (#0B1118), raised rows (#1B2733), thin #3A4A59 divisions and a single #FFD400 selection. HarmonyOS Sans for labels where available; no always-on yellow outlines around every control. Flat rectangular geometry, typography aligned to the 4px scale, icon column of consistent width. Show query, results and keyboard hints clearly. High density but enough room for ten results.

The prior AI mockup is a *direction*, not pixel truth: its left-anchored launcher, file browser and terminal were composed as a single illustration. For testing, define a standalone 1600x900 launcher view and use the actual Rofi screen position. Obtain a user-approved real reference before enforcing pixel thresholds.

## Iteration order

1. Baseline current drun menu in VM. Inspect query field, item height, actual icon sizes, keyboard focus, scaling and font substitution.
2. Geometry only: max width, content height, padding, grouping and search prominence. No palette change in this step.
3. States only: selected vs active/running vs hover, contrast, icon alignment and scroll. Avoid multiple simultaneous accents.
4. Context/help affordances: visible Esc / Enter / arrow hints if supportable with Rofi styling; otherwise document the limitation instead of drawing fake interactive content.
5. Compare Rofi against a **separate Quickshell prototype** only if the original cannot support required structure. Reuse SearchField, Cursor and NavRow primitives rather than writing a parallel navigation engine.

## Functional acceptance

- Super+F opens the correct menu; Escape exits without opening an app.
- Keyboard search filters predictable installed desktop entries; Return opens the chosen entry.
- Long names truncate without colliding with shortcut labels; mouse and keyboard focus remain distinguishable.
- Launcher appears on intended output and does not steal the host's focus (VM-only).
- Screenshot, run JSON, validation notes and remaining deviations are attached to review.

## Decisions to defer

Left vs centered positioning; rows vs grid; whether running windows share the app search. Do not choose by copying a generated illustration alone.
