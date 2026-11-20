# 06 — Tokenized visual variants (after a working launcher)

The repo already contains carefully aligned Endfield colors in QML, Rasi, GTK, Ghostty, Yazi, tmux and Qt. A new theme variant must not create another set of uncoordinated hand edits.

## Options

1. Endfield Refined (first): preserve #0B1118 / #111A23 / #1B2733 and #FFD400, simplify noise and align component geometry.
2. Archive (NieR-inspired, not a game asset replica): warm ivory and brown, sparse borders, technical annotations. First prove readability in terminal and menu.
3. Operations (Death Stranding-inspired, not a game asset replica): gray-blue neutrals, restrained orange/blue signals, operator-console layout.

## Implementation design

Extract semantic tokens to one versioned source file only after verifying that the current eight consumers map to equivalent meanings. Generate target formats with a deterministic script and snapshot-test outputs. Preserve manual source overrides when formats cannot express chamfers/textures. Do not change palette and geometry at the same time.

## Acceptance

For every theme, capture the same launcher, file manager, terminal and sidebar scenes at identical resolution and UI state. The variants must differ in design language rather than gratuitous widgets, animations or background pictures. Keep current Endfield as a fallback through Git, not through untracked live edits.
