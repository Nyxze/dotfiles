---
name: markdown-converter
description: Convert files to Markdown for text analysis using MarkItDown. Use for document and data extraction, including PDF, Office files, HTML, CSV, JSON, and XML; check converter dependencies and extraction quality.
---

# Markdown converter

Use `uvx` to run MarkItDown in a cached tool environment. Include the extra for
the input format; the base package does not install every converter dependency.
See the [supported formats and extras](https://github.com/microsoft/markitdown#optional-dependencies).

```bash
# PDF extraction
uvx --from 'markitdown[pdf]' markitdown input.pdf -o output.md

# Word extraction
uvx --from 'markitdown[docx]' markitdown input.docx -o output.md

# HTML or plain text
uvx markitdown input.html -o output.md

# Binary stdin with a format hint
uvx --from 'markitdown[pdf]' markitdown -x .pdf < input.pdf > output.md
```

Other format extras include `pptx`, `xlsx`, `xls`, `audio-transcription`, and
`youtube-transcription`; `markitdown[all]` includes all optional dependencies.
Inspect the installed CLI's `--help` for additional flags and backend options.

Check the output for missing text, broken tables, and incomplete extraction.
Plain image conversion is not a guarantee of OCR, and scanned PDFs may need an
OCR-capable backend. Audio and video URLs can require external services and
format-specific dependencies. Use an external backend only when it fits the
user's requested workflow and configured access; do not invent endpoints or
credentials. Preserve the source and report any extraction limits.
