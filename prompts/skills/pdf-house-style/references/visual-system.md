# PDF visual system

Read this reference when composing or restyling a PDF in the house style. The stylesheet in `../assets/report.css` owns the exact values; this page explains their use.

## Page and typography

- A4 portrait with 18 mm top, 17 mm side, and 19 mm bottom margins.
- Poppins for document text, headings, table text, labels, and footers. Use a monospace font only for code, logs, traces, and similarly aligned text.
- A restrained hierarchy: large cover title, medium level-one headings, smaller level-two headings with a left rule, and compact captions.
- Navy text with blue-gray accents, pale gray table headers and code backgrounds, and very light zebra rows. Keep ordinary body text dark enough for print.
- Footer label and page number on every page. Avoid decorative headers or large color blocks.

## Document structure

- Use a separate cover and contents page for documents with several major sections. Set `cover: false` and/or `toc: false` in front matter for short documents where those pages would add no value.
- The contents page lists level-one headings and gets its page numbers from the final layout. Do not type page numbers in the source.
- Use `#` for major sections, `##` for subsections, and `###` for captions or small subheadings.
- Add `{: .page-start }` to a level-one heading only when a new page improves the reading sequence.
- Keep a heading with the following paragraph, table, image, or code block. Inspect long blocks after rendering; a block taller than one page may still need editing.

## Figure and table treatment

- Number captions in reading order. Use `Figure N` for images, charts, diagrams, and technical evidence. Use `Table N` when a table needs a formal reference.
- Explain units, series, and the meaning of visual marks inside charts and diagrams. Use the same navy and teal palette, Poppins labels, and adequate contrast.
- Prefer SVG for charts and diagrams because it stays sharp at print size. Use PNG or JPEG for photographs and screenshots. Keep all image files local to the Markdown source.
- Avoid screenshots of tables or code when selectable text can be used instead.
- Keep tables as text with a visible header, light row dividers, and sensible column widths. Check dense tables at actual page size.

The [component catalogue](components.md) gives source patterns. The [gallery PDF](component-gallery.pdf) shows their rendered appearance; its [Markdown source](component-gallery.md) is editable. Run `../scripts/build_gallery.sh` after changing the gallery source or illustration assets to regenerate the PNG example and PDF reference.
