# /// script
# requires-python = ">=3.11"
# dependencies = ["Markdown>=3.11,<4", "PyYAML>=6,<7", "weasyprint>=70,<71"]
# ///

"""Render a self-contained technical report from Markdown to PDF."""

import argparse
from html import escape, unescape
import json
from pathlib import Path
import re

import markdown
import yaml
from weasyprint import CSS, HTML
from weasyprint.text.fonts import FontConfiguration


LABELS = {
    "en": {"contents": "Contents", "author": "Author", "group": "Group", "document_type": "Document", "date": "Date"},
    "fr": {"contents": "Sommaire", "author": "Auteur", "group": "Groupe", "document_type": "Document", "date": "Date"},
}


def read_document(path: Path) -> tuple[dict[str, str], str]:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise ValueError("The Markdown file must start with YAML front matter.")
    end = text.find("\n---\n", 4)
    if end < 0:
        raise ValueError("The YAML front matter must end with a line containing ---.")

    raw = yaml.safe_load(text[4:end])
    if not isinstance(raw, dict):
        raise ValueError("The YAML front matter must contain key-value fields.")
    metadata = {}
    for key, value in raw.items():
        if not isinstance(key, str) or isinstance(value, (dict, list)) or value is None:
            raise ValueError(f"Invalid metadata field: {key!r}")
        metadata[key] = str(value).strip()
    if not metadata.get("title"):
        raise ValueError("The title field is required.")

    body = text[end + 5:].lstrip()
    if not body:
        raise ValueError("The document body is empty.")
    for image in re.findall(r"!\[[^\]]*\]\(([^)]+)\)", body):
        if "://" in image or not (path.parent / image).is_file():
            raise ValueError(f"Image is missing or not local: {image}")
    return metadata, body


def contents(body: str) -> str:
    entries = []
    for attributes, heading in re.findall(r"<h1\b([^>]*)>(.*?)</h1>", body):
        anchor = re.search(r'\bid="([^"]+)"', attributes)
        if not anchor:
            continue
        label = unescape(re.sub(r"<[^>]+>", "", heading))
        numbered = re.fullmatch(r"(\d+)\s*[—-]\s*(.+)", label)
        number = numbered.group(1) if numbered else ""
        name = numbered.group(2) if numbered else label
        entries.append(
            f'<a class="toc-entry" href="#{escape(anchor.group(1), quote=True)}">'
            f'<span class="toc-number">{escape(number)}</span>'
            f'<span class="toc-name">{escape(name)}</span>'
            "</a>"
        )
    if not entries:
        raise ValueError("The document needs at least one level-one heading for the contents page.")
    return "\n".join(entries)


def render_html(metadata: dict[str, str], body: str) -> str:
    fields = {key: escape(value) for key, value in metadata.items()}
    language = metadata.get("lang", "fr").split("-")[0].lower()
    labels = LABELS.get(language, LABELS["en"])
    kicker = " · ".join(fields.get(key, "") for key in ("document_type", "group") if fields.get(key))
    cover_details = "\n".join(
        f'<div><span>{labels[key]}</span><strong>{fields[key]}</strong></div>'
        for key in ("author", "group", "document_type", "date")
        if fields.get(key)
    )
    cover_metadata = f'<div class="cover-metadata">{cover_details}</div>' if cover_details else ""
    subtitle = f'<p>{fields["subtitle"]}</p>' if fields.get("subtitle") else ""
    toc = contents(body)
    return f'''<!doctype html>
<html lang="{escape(metadata.get('lang', 'fr'), quote=True)}">
<head><meta charset="utf-8"><title>{fields['title']}</title></head>
<body>
  <section class="cover">
    <div class="cover-kicker">{kicker}</div>
    <div class="cover-main">
      <h1>{fields['title']}</h1>
      <div class="cover-rule"></div>
      {subtitle}
    </div>
    {cover_metadata}
  </section>
  <nav class="toc" aria-label="{labels['contents']}">
    <div class="toc-kicker">{escape(metadata.get('footer', metadata['title']))}</div>
    <h1>{labels['contents']}</h1>
    <div class="toc-entries">{toc}</div>
  </nav>
  <main class="report">{body}</main>
</body></html>'''


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="Markdown source with YAML front matter")
    parser.add_argument("output", type=Path, help="PDF to create")
    args = parser.parse_args()

    source = args.source.resolve()
    output = args.output.resolve()
    try:
        metadata, document = read_document(source)
        body = markdown.markdown(document, extensions=["tables", "fenced_code", "toc", "attr_list"])
        html = render_html(metadata, body)
    except (OSError, ValueError, yaml.YAMLError) as error:
        parser.error(str(error))

    stylesheet = Path(__file__).resolve().parents[1] / "assets" / "report.css"
    footer = json.dumps(metadata.get("footer", metadata["title"]), ensure_ascii=False)
    fonts = FontConfiguration()
    output.parent.mkdir(parents=True, exist_ok=True)
    HTML(string=html, base_url=str(source.parent)).write_pdf(
        str(output),
        stylesheets=[
            CSS(filename=str(stylesheet), font_config=fonts),
            CSS(string=f"@page {{ @bottom-left {{ content: {footer}; }} }}", font_config=fonts),
        ],
        font_config=fonts,
    )
    print(output)


if __name__ == "__main__":
    main()
