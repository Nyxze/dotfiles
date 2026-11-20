# 02 — File manager surfaces (Nautilus first)

## Existing ownership

- home/common/.config/gtk-4.0/gtk.css — Nautilus/GTK4 appearance
- home/common/.local/share/icons/endfield/index.theme — inherits Papirus-Dark
- home/mint-xfce/.local/share/themes/Endfield/gtk-3.0/gtk.css — Thunar/GTK3 alternative
- home/mint-xfce/.config/Thunar/uca.xml — custom actions
- tools/visual-harness/fixtures/files/ — reproducible small directory tree

## Visual target

An industrial file manager with a quiet dark canvas, strongly readable folders, a compact pathbar, a sober sidebar and high-contrast selected items. Folder icons are yellow: **never** fill selected file rows with the same yellow, which makes icons disappear. Use a raised dark selection plate plus yellow border/label as the existing design system prescribes.

Aim for clean navigation and context menus; do not attempt to turn Nautilus into a completely custom QML file manager. Respect GTK4/libadwaita internal selector instability and accessibility.

## Iterations

1. Capture fixed fixture at 1600x900 and record Nautilus version, GTK version and loaded icon theme.
2. Tune pathbar and toolbar separately. Check address editing, search field, normal vs unfocused state.
3. Tune sidebar and grid/list selection separately, including keyboard multi-selection and renaming.
4. Tune right-click context menus, tooltips, scrollers and mount indicators.
5. Audit icon coverage: missing icons, active-state contrast, symlinks and executable badges.
6. Only after Nautilus acceptance, port colors/spacing to Thunar GTK3 on Mint, validating it in a separate X11/i3 guest.

## Functional acceptance

Open directories; back/forward; rename; context actions; drag-and-drop; search; keyboard focus; files with long names; selection persists. Confirm selected icons are visible. Do not break Nautilus accessibility or GTK defaults globally.

## Not in scope

Replace Nautilus with a fictional file manager seen in an AI render; force fragile GTK selectors into application internals; introduce KDE/Dolphin solely to match a mockup. Dolphin can be evaluated later if Plasma becomes an actual profile.
