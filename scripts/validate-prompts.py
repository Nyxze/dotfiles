#!/usr/bin/env python3
"""Check local documentation links and personal skill names."""

import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parents[1]
MARKDOWN_LINK = re.compile(r"\[[^\]]+\]\((<[^>]+>|[^\s)]+)\)")
HOME_PATH = re.compile(r"(?<!\w)/home/[A-Za-z0-9_-]+")
WORD = re.compile(r"\b[\w'-]+\b")


def local_targets(path):
    for match in MARKDOWN_LINK.finditer(path.read_text()):
        target = match.group(1).strip("<>")
        parsed = urlsplit(target)
        if parsed.scheme or parsed.netloc or not parsed.path:
            continue
        yield target, path.parent / unquote(parsed.path)


def validate_document(path):
    errors = []
    body = path.read_text()
    for target, destination in local_targets(path):
        if target.startswith("/"):
            errors.append(f"{path.relative_to(ROOT)}: absolute local link: {target}")
            continue
        if not destination.exists():
            errors.append(f"{path.relative_to(ROOT)}: missing link: {target}")
    if HOME_PATH.search(body):
        errors.append(f"{path.relative_to(ROOT)}: machine-specific home path")
    return errors


def validate_navigation():
    documents = set((ROOT / "prompts/knowledge").rglob("*.md"))
    documents.add(ROOT / "prompts/MAIN.md")
    documents.add(ROOT / "prompts/skills/INDEX.md")
    documents.update((ROOT / "prompts/providers").rglob("*.md"))
    documents.update((ROOT / "prompts/skills").glob("*/SKILL.md"))
    entry = ROOT / "prompts/knowledge/AGENTS.md"
    reached = set()
    pending = [entry]
    while pending:
        page = pending.pop()
        if page in reached:
            continue
        reached.add(page)
        pending.extend(destination.resolve() for _, destination in local_targets(page)
                       if destination.resolve() in documents)
    return [f"{page.relative_to(ROOT)}: unreachable from the global entry point"
            for page in sorted(documents - reached)]


def validate_index(path):
    errors = []
    for line in path.read_text().splitlines():
        if not line.startswith("|") or line.startswith("| ---") or "Open when |" in line:
            continue
        cells = [cell.strip() for cell in line.strip("|").split("|")]
        if not MARKDOWN_LINK.fullmatch(cells[0]) or len(WORD.findall(cells[-1])) < 3:
            errors.append(f"{path.relative_to(ROOT)}: index row needs a link and a useful trigger")
    return errors


def validate_budget(path, limit):
    count = len(WORD.findall(path.read_text()))
    if count > limit:
        return [f"{path.relative_to(ROOT)}: {count} words exceed the {limit}-word entry-point budget"]
    return []


def main():
    documents = [ROOT / "AGENTS.md", *(ROOT / "prompts").rglob("*.md")]
    errors = [error for path in documents for error in validate_document(path)]
    errors.extend(validate_navigation())
    for path in (ROOT / "prompts/knowledge").rglob("INDEX.md"):
        errors.extend(validate_index(path))
        errors.extend(validate_budget(path, 120))
    skills_index = ROOT / "prompts/skills/INDEX.md"
    errors.extend(validate_index(skills_index))
    errors.extend(validate_budget(skills_index, 150))
    errors.extend(validate_index(ROOT / "prompts/MAIN.md"))
    errors.extend(validate_budget(ROOT / "prompts/MAIN.md", 380))
    errors.extend(validate_budget(ROOT / "prompts/knowledge/AGENTS.md", 240))
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
