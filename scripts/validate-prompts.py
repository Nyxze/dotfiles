#!/usr/bin/env python3
"""Check local documentation links and personal skill names."""

import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parents[1]
MARKDOWN_LINK = re.compile(r"\[[^\]]+\]\((<[^>]+>|[^\s)]+)")
HOME_PATH = re.compile(r"(?<!\w)/home/[A-Za-z0-9_-]+")


def validate_document(path):
    errors = []
    body = path.read_text()
    for match in MARKDOWN_LINK.finditer(body):
        target = match.group(1).strip("<>")
        parsed = urlsplit(target)
        if parsed.scheme or parsed.netloc or not parsed.path:
            continue
        if parsed.path.startswith("/"):
            errors.append(f"{path.relative_to(ROOT)}: absolute local link: {target}")
            continue
        destination = path.parent / unquote(parsed.path)
        if not destination.exists():
            errors.append(f"{path.relative_to(ROOT)}: missing link: {target}")
    if HOME_PATH.search(body):
        errors.append(f"{path.relative_to(ROOT)}: machine-specific home path")
    return errors


def main():
    documents = [ROOT / "AGENTS.md", *(ROOT / "prompts").rglob("*.md")]
    errors = [error for path in documents for error in validate_document(path)]
    for skill in (ROOT / "prompts/skills").iterdir():
        manifest = skill / "SKILL.md"
        if not manifest.exists():
            continue
        match = re.search(r"^name: (.+)$", manifest.read_text(), re.MULTILINE)
        if not match or match.group(1) != skill.name:
            errors.append(f"prompts/skills/{skill.name}: skill name does not match directory")
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"Validated {len(documents)} Markdown files and personal skill names.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
