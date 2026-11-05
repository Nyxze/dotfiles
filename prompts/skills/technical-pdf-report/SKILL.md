---
name: technical-pdf-report
description: Create or restyle sober professional, technical, or academic PDF reports with the user's reusable Poppins layout. Use when the user asks for a dossier, technical report, school report, research write-up, or future PDF in the established house style, even if they do not name this skill. Do not use for simple PDF extraction, merging, or forms.
---

# Technical PDF report

Use the bundled Markdown-to-PDF renderer and stylesheet as the visual source of truth. They preserve the approved report style across projects without carrying over content from the original dossier.

## Visual contract

- A4 pages with restrained navy, blue-gray, and teal accents; ample margins and space between sections.
- Poppins for titles, prose, tables, figure labels, captions, contents, and footers. Use monospace for code, SQL, traces, and plan trees.
- A dedicated cover, then a contents page listing level-one headings, then the report. The renderer calculates page numbers.
- The same footer and page number on every page, including cover and contents.
- Light table rules, subtle alternating rows, readable column widths, and numbered figure captions.
- Keep headings with their following content and short code blocks intact. Review long blocks and tables after rendering.
- Prefer clear evidence, labels, and spacing to decorative elements. Do not add filler text to the contents page.

## Workflow

1. Read the user's source and project instructions. Preserve its language, facts, terminology, and required output format. Apply project-specific content rules separately from this style.
2. Prepare a Markdown source with YAML front matter. `title` is required. `subtitle`, `document_type`, `author`, `group`, `date`, `footer`, and `lang` are optional. French is the default label language; set `lang: en` for English output. Start each major part with `#`. Use `##` for sections and `### Figure N: ...` for numbered figures. Add `{: .page-start }` to a level-one heading only when it needs a new page.
3. Keep images as local files beside the source or at relative paths. Set figure text to Poppins when creating charts or diagrams. Keep tables as Markdown tables and code or plan trees in fenced blocks. Include the evidence inside the report when the deliverable must stand alone.
4. Render with `uv run --script <skill>/scripts/render_pdf.py SOURCE.md OUTPUT.pdf`, replacing `<skill>` with this skill's directory. The renderer reads `assets/report.css` and bundles its Poppins font files into the PDF.
5. Render the PDF pages to images and inspect the cover, contents, dense tables, figures, and page boundaries. Check for overlap, clipped text, broken captions, empty pages, and isolated headings. Check the page numbers and figure sequence. Adjust the source or stylesheet and render again if needed.
6. Deliver the final PDF. Keep the Markdown and renderer available as sources for later edits when the project allows them.

For a minimal input, see [the example](assets/example.md). The script accepts input and output paths from any working directory and prints the completed PDF path. If `uv` or WeasyPrint's system libraries are unavailable, report the missing dependency instead of silently changing the layout engine.
