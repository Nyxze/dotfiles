# HTML presentation contract

The artifact is a single `architecture.html` viewable locally without a build
step. Embed CSS, required scripts, and assets. Core information must remain
readable without JavaScript and without a network connection. Prefer rendering
Mermaid diagrams to embedded SVG; a remote Mermaid CDN alone does not satisfy
the offline contract. Use SVG directly when it gives clearer layout control.

## Visual direction

Use a dark technical documentation style with an engineering-blueprint feel:
geometric shapes, precise alignment, generous spacing, concise labels, clear
arrows, strong typography, subtle borders, minimal shadows, and restrained color.
Avoid decorative illustrations, generic dashboard cards, excessive gradients,
rounded panels, oversized headings, and meaningless icons.

A suitable starting palette:

```css
--background: #0b0d10;
--surface: #11151a;
--surface-elevated: #171c22;
--border: #252c34;
--text: #e6eaf0;
--text-muted: #8b95a3;
--accent: #5cc8ff;
```

Use the accent for links, selection, and architectural boundaries. Additional
colors should encode meaning, such as uncertainty or asynchronous interaction.
Keep contrast sufficient for both text and diagrams.

## Navigation and evidence

Use a persistent sidebar on larger screens, anchor navigation, and a compact
header describing the repository. Adapt to smaller screens and provide legible
print styles. Keep code paths and symbols identifiable and easy to copy. Add
remote source links only when their repository, revision, and location are
verified; static paths remain useful without a remote.

Distinguish observed facts, interpretations, recommendations, and unknowns.
Component summaries can include their type, location, responsibility, important
symbols, dependencies, and dependents. Use them for meaningful components only.

## Diagrams and interaction

Prefer several focused context, component, sequence, data, or deployment diagrams
to a giant dependency graph. Keep labels readable and layout uncluttered. Use
consistent shapes and arrows: rectangles for components, cylinders for storage,
and distinct direct/asynchronous connections when helpful. Define any semantics
that might otherwise be ambiguous.

Add only useful interactions: section expansion, copy path/symbol, diagram focus,
or in-document search. Navigation and primary content must work without them.
Test diagram clipping, anchor targets, responsive overflow, keyboard access, and
print contrast alongside offline rendering.
