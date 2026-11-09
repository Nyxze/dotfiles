---
name: pdf-house-style
description: Create or restyle any PDF document with the user's reusable, restrained Poppins visual style. Use for reports, notes, guides, dossiers, reference sheets, and other PDFs when the user wants the established look or gives no different visual direction. Do not use for pure PDF reading, extraction, merging, or form filling when layout is not being changed.
---

# PDF house style

This skill controls presentation only. The examples contain placeholder content and are never sources of facts, terminology, names, or numbers for a user's document. Follow the user's content and any project instructions independently.

## References and assets

- Read the [visual system](references/visual-system.md) whenever creating or restyling a PDF. It explains the layout choices; `assets/report.css` owns exact values.
- Read the [component catalogue](references/components.md) when the document needs tables, images, charts, diagrams, code, or callouts. Open the [rendered gallery](references/component-gallery.pdf) when a visual example helps choose a component. Its [source](references/component-gallery.md) contains only neutral placeholders.
- Use `assets/fonts/poppins/` for embedded Poppins files. Keep the bundled license with them.

## Workflow

1. Inspect the source and preserve its language, meaning, facts, and required output. If only an existing PDF is available, extract and rebuild its content with PDF tools, then compare the result with the original for omissions. Select components for the information being shown; do not insert gallery text or values into the document.
2. For a text-led document, use the bundled Markdown renderer. Start from [minimal input](references/minimal-input.md), replace every placeholder, and use YAML front matter. `title` is required; `subtitle`, `document_type`, `author`, `group`, `date`, `footer`, and `lang` are optional. Labels default to French; set `lang: en` for English. Set `cover: false` or `toc: false` for a short document that does not need those pages. Both default to true.
3. Use level-one headings for major sections and level-two headings for subsections. The contents page, when enabled, is generated from level-one headings. Add `{: .page-start }` only where a section should begin on a new page. Put local images beside the source or at relative paths. Follow the caption and component patterns in the catalogue.
4. Render with `uv run --script <skill>/scripts/render_pdf.py SOURCE.md OUTPUT.pdf`, replacing `<skill>` with this skill's directory. For a PDF whose source must stay in another format, apply the same visual system with its authoring tool and inspect the resulting PDF.
5. Render pages to images and inspect the cover, contents, dense components, and page boundaries. Check legibility at actual page size, captions, page numbers, clipping, overlap, empty pages, and isolated headings. Fix the source or styling and render again.
6. Deliver the final PDF and retain editable source files when the project permits them.

The renderer accepts paths from any working directory and prints the completed PDF path. If `uv` or WeasyPrint's system libraries are unavailable, report the missing dependency instead of silently changing the layout engine.
