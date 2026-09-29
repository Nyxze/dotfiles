# The endfield interface language

The palette is named after Arknights: Endfield, and its menus are the reference
for more than the colours. This file records what the language is, so a surface
built in QML, GTK CSS, rasi or SVG lands on the same one instead of each being
invented again.

Two sources feed it. `endfield_desktop_design_system.pdf` is the specification:
it names the tokens, the type scale, the spacing unit and the layering model,
and it wins wherever it says anything. The measurements below were taken off
native captures of the game's own menus, and they cover what a specification
does not — texture pitch, texture amplitude, how much of a screen is allowed to
carry colour at all.

## Where the tokens live

The same palette exists seven times over, because no two of these parsers share
a syntax:

| File | Reads |
| ---- | ----- |
| `endfield.css` | waybar, swaync, nwg-bar, gtk3, gtk4 |
| `endfield.conf` | hyprlock |
| `endfield.lua` | Hyprland |
| `endfield.rasi` | rofi |
| `quickshell/endfield/Theme.qml` | the quickshell shell |
| `ghostty/themes/endfield` | the terminal |
| `qt5ct/colors/endfield.conf`, `qt6ct/colors/endfield.conf` | Qt applications |

The SDDM greeter is the exception and deliberately not an eighth copy: its
`Theme.qml` and the components it shares are derived from the quickshell config
by `scripts/install-system.sh`, so the palette has nowhere new to drift to.

A colour changed in one has to be changed in all of them. Names are semantic
everywhere: a theme may remap a value, but what a token *means* stays put.

| Token | Value | Use |
| ----- | ----- | --- |
| `bg-deep` | `#0B1118` | deepest surface: the desktop, and the wells that take input |
| `bg-panel` | `#111A23` | windows and panels |
| `bg-raised` | `#1B2733` | plates, cards, popovers, hover |
| `line` | `#3A4A59` | borders and dividers |
| `text-primary` | `#E8EDF1` | primary text |
| `text-secondary` | `#AAB7C2` | secondary text |
| `text-muted` | `#8A99A6` | metadata, serials, technical notes |
| `accent` | `#FFD400` | brand accent, focus, attention |
| `accent-soft` | `#FFE14D` | the same hue used as a foreground |
| `info` | `#4B9BFF` | informational |
| `success` | `#8BD32E` | success, connected |
| `danger` | `#FF6B45` | critical, destructive |
| `on-accent` | `#0B1118` | anything sitting on an accent, success or danger fill |

`text-muted` is not in the specification; it is the step the metadata register
needs, placed on the `line`-to-`text-secondary` ramp at the lightest value that
still clears 4.5:1 against `bg-raised`. `on-accent` is a single token rather
than a per-fill choice because white fails on `danger` at 2.4:1 — there is no
case where the inverted foreground should be anything else.

## Colour is punctuation, not a surface treatment

Over a full menu screen: **95.5% of pixels are near-neutral, 3% are strongly
coloured.** Every plate, every panel, every glyph is neutral. Colour appears
only where something has to be said.

There is one accent and three things to say with it, so each gets its own
shape and they never trade:

- **Fill — the one chosen among several.** The connected network, the current
  band, the selected navigation row. Not a flat plate: the accent body carries
  the hatch in the deepest surface, its trailing edge is a long shallow
  diagonal, and two stepped bands of the same accent at 62% and 46% trail off
  behind it with a brighter hairline at the step. Text on it is `on-accent`,
  and has to clear the bands — they reach further left at the bottom than at
  the top, by the whole slant. A pill is too narrow for the tail and takes the
  hatch alone.

  The tail is a fifth of the row's width, not a multiple of its height. Both
  readings fit the source, whose rows happen to have the aspect that makes them
  agree, but only the first is expressible in GTK and rofi — they place their
  stops proportionally and know nothing about the row's height.
- **Rail — switched on, independently of anything else.** A 4px accent bar on
  one edge. A quick-settings tile is a toggle, not a choice: filling four of
  them would turn most of a panel yellow, and none of them is "the one".
- **Border — where the cursor is.** 2px accent, inverting to `on-accent` once
  the cursor lands on a filled row so it stays visible against the yellow.

The fill has one exception, and it is a consequence of the icons. A file
manager's rows and tiles carry folder icons that are themselves the accent, so
a yellow plate behind one erases the thing being selected. There, selection
takes the border and an accent label instead — same signal, a shape that does
not collide with its own content. The sidebar keeps the fill, because its icons
are symbolic and recolour to `on-accent`.

Collapsing any two of these leaves a row that is both under the cursor and
chosen with nothing left to say.
- **Hover never borrows the accent.** It raises the surface and answers with a
  neutral underline. Pressing puts an accent bar on the leading edge.
- **Primary takes the accent as a fill, secondary as a hairline.** A confirm is
  a yellow plate with dark text; a cancel is a dark plate inside a yellow
  hairline. Two buttons that both shout are two buttons nobody reads.

Hover and press are GTK's, not the shell's. Quickshell has a single highlight —
`Cursor`, written by the mouse and the keyboard alike — and that highlight is
what carries the accent fill. A second channel grafted onto it would break the
one invariant the keyboard navigation rests on.

## Type

One font value per role, assigned whole, so a size and its weight cannot drift
apart at a call site. Uppercase is baked into the roles that always carry it:
navigation labels, metadata, status tags, section headings — never long copy.

| Role | Size / line | Weight | Use |
| ---- | ----------- | ------ | --- |
| display | 32 / 36 | 700 | page title |
| h2 | 20 / 24 | 650 | window and section title |
| h3 | 14 / 18 | 650 | subsection, card title |
| body | 13 / 20 | 400 | default UI copy |
| bodySmall | 11 | 400 | a value read off a device |
| label | 11 / 14 | 600, uppercase | control labels, tabs |
| micro | 9 / 12 | 500, uppercase, condensed | serials, metadata |
| numeric | 24 / 28 | 650 | primary metric, clock |

`bodySmall` is `label`'s size without its capitals. An SSID, a percentage, a
device name is data, and uppercasing data corrupts it.

The UI face is HarmonyOS Sans. Micro-data takes HarmonyOS Sans Condensed — the
condensed technical face the specification reserves for serials and metadata,
and the one part of its two-face system that was already installed.

## Geometry

Base unit 4px. Every margin, gap and size is a multiple of it; `Theme.space(n)`
takes the step count rather than the pixel value, which is what keeps a stray 9
or 14 out.

Panel border 1px, emphasis border 2px. Motion: 100ms on hover, 80ms on press,
180ms opening — short, linear-to-eased, and never a large zoom.

## Corners are cut, not rounded

**4 to 6 px at 45 degrees, and only on some corners of a given plate.** The
active tab cuts its two top corners; the row plates cut 4-6px. The restraint is
the point — the plates read as machined, not as parallelograms. The cut is a
geometric replacement for a radius, not an addition to one, so there is no
rounding left anywhere — with one exception, which the concept boards make
themselves: **the switch stays a pill.** Every plate around it is bevelled, but
the travel of a knob along a track is what reads as a switch at all; bevel it
and it reads as a very small button.

## The textures, and they are not interchangeable

| | grid | hatch | hatch-dark | dots |
| --- | --- | --- | --- | --- |
| pattern | orthogonal, 0 and 90 degrees | diagonal | diagonal | staggered, a screen turned 45 degrees |
| pitch | 4.4 - 4.8 px | 3.2 px | 3.2 px | 5 px along the axis, 10 px on the tile |
| light | `text-primary` | `text-primary` | `bg-deep` | `text-primary` |
| for | large grounds | contained plates | plates filled with the accent | halftone fields, never a flat ground |

**The terminal takes none of them, and that is settled.** Every one was tried
there, along with contours, registration marks and a tube's scanline and
grain. Each either vanished at the amplitude a material wants or got in the
way at the amplitude that made it visible. It is the one surface whose content
is itself a grid of glyphs and which someone reads for hours, so a texture
behind it has no correct amplitude, only a least bad one. It wears the
palette, the cell height and the padding instead.

`hatch-dark` exists because a light hatch over yellow has nothing to darken.
Same geometry, the deepest surface instead of the lightest.

The hatch spread across a large ground stops reading as a material and starts
reading as a filter laid over the interface. That is the whole rule for which
surface takes which.

The greeter is the one exception, and it is worth stating rather than leaving as
a contradiction: it carries the hatch across the whole screen. There is no
interface underneath it to be filtered — one plate on an otherwise empty ground
— so the only thing the diagonal can read as there is the ground's own texture.

**The diagonal runs bottom-left to top-right.** Variance collapses along that
axis (2.9) and not the other (116), so there is no ambiguity. In CSS,
`repeating-linear-gradient(135deg, ...)` is the one that produces it.

Amplitude is the peak-to-peak swing of the fundamental, as a percentage of the
surface's mean luminance. A hard 1px-on, 3px-off square wave needs roughly
`rgba(<light>, 0.13)` over a mid plate to land in range; matching by alpha
alone, without measuring, misses badly.

The `.svg` files are how the textures are derived; the `.png` files are what
every engine actually loads, and each carries its own regeneration command. Nine
pixels square with two diagonals gives a 3.18px pitch, within 0.02px of the
measured hatch; the dot screen needs a coarser tile and takes ten.

## Halftone is a device, not a material

The source leans on halftone the way it leans on the hatch, and in both forms:
a screen of dots, and a screen of lines. What makes either one a halftone is not
the tile, which is just a texture — it is that the screen is *bounded*, dense in
one region and absent in another, so it reads as a field with a shape rather
than as a surface treatment. A tiled screen under a radial mask is that, and any
tile works — `dots` and `hatch` alike.

This is the one place the amplitude rule above does not apply, and the gap is
not small. A material sits at 1 - 3%; the dot screen at its peak measures 36%,
an order of magnitude up. That is the point — a halftone is meant to be seen as
a graphic, which is exactly why it has to be masked into a bounded shape and can
never be laid flat across a surface the way the grid and the hatch are.

Two traps, both costly before they were written down:

- **Take the mask's radius from the shorter side of the screen.** On a radius
  taken from the longer one the ring never completes inside a 16:9 frame, and
  what should read as a disc comes out as a dome pinned to the top and bottom
  edges.
- **Stagger the tile.** A halftone screen is a square grid turned 45 degrees.
  One dot in the corner of a tile gives an orthogonal grid of dots, which reads
  as pixels; two on the diagonal give the turn.

The tile and the traps are settled; no surface carries a halftone field today.
It stays defined here because the source uses it constantly and the next ground
that needs one should not have to re-derive the pitch, the stagger and the mask.

## The greeter's ground

A wireframe terrain in perspective, dissolving into the deepest surface at every
edge, and drifting toward the viewer. It is the one surface in this repository
that is generated rather than authored, and it exists twice over: a pair of
shaders draw and animate it on the GPU, and `greeter.py` emits `greeter.svg` —
rasterised to `greeter.png` like every other texture here — as the still the
greeter falls back to if the shaders do not load.

Two copies of one shape is a cost, and it is the right one. The fallback is not
optional: a login screen that comes up empty because a `.qsb` went missing
leaves nobody anywhere to fix it from. So the projection and the noise are
written twice, in GLSL and in Python, and a change to the shape belongs in both.
The still carries no ground of its own for the same reason — the greeter lays
its own surface and hatch underneath, and the two paths have to stack
identically.

Generated, because the alternative does not work. A ridgeline drawn by hand
reads as a vector illustration — smooth, deliberate, obviously a curve somebody
placed. A heightmap of summed noise, folded about its midpoint so the rounded
hills come out as crests, reads as terrain. Six octaves, smoothstepped between
lattice points; a linear blend leaves the lattice visible as a crease along
every cell boundary, which on a wireframe is unmistakable.

The wireframe itself is drawn by neither geometry nor a texture: the fragment
shader measures the distance from each pixel to the nearest cell boundary of the
interpolated grid coordinate and divides it by that coordinate's screen-space
derivative. The stroke then stays one pixel wide however far the perspective
stretches or compresses the cell, and the far rows thin out on their own as
their cells fall below a pixel — which is the same dissolve the still gets from
its depth fade, arrived at from the other direction.

Two things the mesh has to respect, and neither is obvious until it is wrong:

- **It is a ground, so it must not be readable before the plate is.** Stroke
  opacity tops out at 0.33 on the nearest row and falls to 0.03 at the horizon.
  At the brightness a mesh wants to be drawn at, it becomes the subject and the
  login plate becomes an obstruction laid over it.
- **The vignette is elliptical, not circular.** On a circular falloff in a 16:9
  frame the top and bottom go black while the left and right thirds are still
  lit, and the terrain ends in mid-air at both sides.

An SVG is text, which is the whole reason the ground is one: its colours are the
real tokens rather than hex baked into pixels, it re-renders at any resolution,
and a change to it reads as a diff. A ground that arrived as a bitmap would be
the one surface here that could not follow a palette change.

## What each engine can express

| Engine | Texture | Chamfer |
| ------ | ------- | ------- |
| GTK4 CSS | `repeating-linear-gradient` or the PNG | painted corner triangles |
| GTK3 CSS | same | same |
| QML | the tiled PNG through `Texture` | `ChamferedRect`, a real cut |
| rasi | a two-stop angled gradient, nothing that repeats | none |
| SVG | `<pattern>` | path geometry |

**GTK has no `clip-path`.** A chamfer there is painted, not clipped: a triangle
in the ground colour laid over each corner. It therefore only works where the
plate sits on a flat, known ground — which is why the Nautilus pathbar has one
and a waybar module, floating over the wallpaper, does not. Everything GTK
cannot cut is square instead.

**rasi has gradients, but not the one that matters.** It parses
`linear-gradient(135deg, a, b)` and `url("file.png", both|width|height|none)`,
and it takes per-side borders, so an accent rail on a row is reachable. It does
not parse `repeating-linear-gradient`, and `url` scales its image to the widget
rather than tiling it, so neither texture can be laid in rofi without
pre-rendering a PNG at the exact window size — which changes with the monitor.
rofi therefore wears the palette and the flat geometry, and no material.

**A QML `Shape` does not clip its children.** `ChamferedRect` cuts its own fill,
but a texture laid inside it runs into the corners. That is tolerable for the
grid, at 1% amplitude, and would not be for the hatch. `ShapePath.fillItem`
looks like the answer and is not: fed an invisible `Image` it draws nothing.

Bounding the texture by hand does not work either, and both ways of getting that
wrong look plausible. `BannerPlate`'s body leans left as it descends, so a
rectangular bound at its top corner leaves the hatch spilling onto the first
band as a dirty wedge, and one at its bottom corner leaves a bare sliver of fill
along the diagonal. No vertical line is the right one.

The answer is a mask: the body is drawn a second time as a white silhouette and
handed to a `MultiEffect` as `maskSource`, which follows the real edge. That is
first-party Qt6 and needs no shader of our own, so it is the technique to reach
for wherever a material has to stop on a diagonal or a cut.

**Ghostty is linear on both paths, and it costs a whole afternoon twice.** A
background image laid at the 1.6% alpha a material wants comes back four to
five times stronger, and the darker the surface the worse the gap: over
`bg-deep` the grid measured 85% peak-to-peak where it was authored for 2%.
`background-image-opacity` scales the same blend, so compensating means a magic
alpha tuned to one blend and one surface; flattening the tile onto its own
ground is the only honest fix. A `custom-shader` has the identical problem one
layer up — `iChannel0` arrives linear and the result is re-encoded, so an
amount added there lands nowhere near where it was aimed. A shader that means
its constants converts to sRGB, works, and converts back.

**A QML shader has to be precompiled.** Qt6 dropped inline GLSL, so a shader
goes through `qsb` into a `.qsb` before QML will load it, and `qsb` ships with
`qt6-shadertools` without landing on `PATH`. That is a build step, and the
greeter's terrain is the only thing here that earns one — a mesh of forty
thousand segments cannot be animated any other way, and neither a frame sequence
nor `Canvas` comes close. Everything else stays out of it: `MultiEffect` covers
masking, and a chamfer is a real cut rather than anything painted over.

## Icons

The concept boards answer this directly: a folder is a flat accent plate, not a
neutral one. The theme is `.local/share/icons/endfield`, a thin override layered
on Papirus-Dark, and it draws the folder family itself — body in the accent, a
darker strip along the fold, one dark micro chip on the edge, and the same 45
degree cut at the bottom right as every other plate.

Emblems are solid geometry, not outlines: the specification asks for a 1.5-2px
stroke set, but a stroke that survives at 24px closes into a blob at the 22px
the sidebar uses, so the register here is filled and compact. The 16px plate
carries no emblem at all for the same reason.

Overriding only the generic folder is not enough. GTK resolves `folder-music`,
`folder-pictures`, `user-home` and the rest by name, and anything left out falls
through to Papirus and comes back blue next to a yellow neighbour — which is
why the override covers the whole family rather than one icon.

## Devices worth stealing

Beyond colour and texture, the menus lean on a small set of repeated moves:

- a left accent bar on a list row carries its state, rather than a fill
- section headers are a small badge, a label, then a long thin rule
- a bounded halftone screen, dots or lines, giving an empty ground a shape
- oversized display text, clipped by its own plate, used as background texture
- crosshair registration marks outside panel corners
- state shown by inversion, a completed row flipping dark with a solid accent block

The first two are in the components, and the crosshairs are on the greeter,
which is the one screen static enough to carry them. The rest are not yet built
anywhere.

Serial numbers and microtext chips are **not** on this list and will not be.
Every board carries them and they are the one device that stays decoration: a
deliberately unreadable string is noise on a desktop someone actually works in,
whatever it does for a game's fiction.

## Still open

- the yellow diagonal hazard bars, a motif of all three concept boards, absent
  from every surface
- whether waybar's own type should come down onto the scale; the bar is chrome
  and the specification does not size it, so it still runs at 15-16px
- ANSI needs eight hues and this palette defines four, so the terminal's magenta
  and cyan are derived to sit on the blue's lightness and chroma band rather
  than specified
