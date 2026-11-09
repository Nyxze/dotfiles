#!/usr/bin/env python3
"""Check the navigation, local links, and personal skill contracts of the documentation under .agents."""

import argparse
import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

from lib.skill_manifest import read_manifest


ROOT = Path(__file__).resolve().parents[1]
INLINE_LINK = re.compile(r'\[[^\]\n]+\]\(\s*(?:<([^>]+)>|((?:[^\s()]|\([^()]*\))+))(?:\s+"[^"]*")?\s*\)')
REFERENCE = re.compile(r'^ {0,3}\[([^\]]+)\]:\s*(?:<([^>]+)>|(\S+))', re.MULTILINE)
REFERENCE_LINK = re.compile(r'\[([^\]\n]+)\]\[([^\]\n]*)\]')
SHORTCUT = re.compile(r'(?<!!)\[([^\]\n]+)\](?![\[(])')
HOME_PATH = re.compile(r'(?<!\w)/home/[A-Za-z0-9_-]+')
WORD = re.compile(r"\b[\w'-]+\b")
ENTRY_WORDS = 800
INDEX_WORDS = 200
SKILL_LINK = re.compile(r'([^/]+)/SKILL\.md')


def prose(text):
    lines = []
    fence = None
    for line in text.splitlines():
        match = re.match(r'^\s{0,3}(`{3,}|~{3,})', line)
        if match:
            marker = match.group(1)
            if fence is None:
                fence = marker
            elif marker[0] == fence[0] and len(marker) >= len(fence):
                fence = None
            continue
        if fence is None:
            lines.append(line)
    return '\n'.join(lines)


def links(text):
    text = prose(text)
    definitions = {m.group(1).casefold(): m.group(2) or m.group(3) for m in REFERENCE.finditer(text)}
    text = REFERENCE.sub('', text)
    text = re.sub(r'(`+).*?\1', '', text)
    targets = [m.group(1) or m.group(2) for m in INLINE_LINK.finditer(text)]
    targets.extend(re.findall(r'^@([^\s]+)\s*$', text, re.MULTILINE))
    remaining = INLINE_LINK.sub('', text)
    for match in REFERENCE_LINK.finditer(remaining):
        key = (match.group(2) or match.group(1)).casefold()
        if key not in definitions:
            raise ValueError(f'undefined link reference: {key}')
        targets.append(definitions[key])
    remaining = REFERENCE_LINK.sub('', remaining)
    targets.extend(definitions[m.group(1).casefold()] for m in SHORTCUT.finditer(remaining)
                   if m.group(1).casefold() in definitions)
    return targets


def anchors(text):
    text = prose(text)
    result = set(re.findall(r'<(?:a|h[1-6])\b[^>]*\bid=["\']([^"\']+)', text))
    counts = {}
    lines = text.splitlines()
    headings = []
    for index, line in enumerate(lines):
        match = re.match(r'^ {0,3}#{1,6}\s+(.+?)(?:\s+#+)?$', line)
        if match:
            headings.append(match.group(1))
        elif index and re.fullmatch(r' {0,3}(?:=+|-+)\s*', line) and lines[index - 1].strip():
            headings.append(lines[index - 1].strip())
    for heading in headings:
        heading = re.sub(r'<[^>]*>', '', heading)
        heading = re.sub(r'\[([^\]]+)\]\([^)]*\)', r'\1', heading)
        slug = re.sub(r'[^\w\-\s]', '', heading.lower()).replace(' ', '-')
        count = counts.get(slug, 0)
        counts[slug] = count + 1
        result.add(f'{slug}-{count}' if count else slug)
    return result


def local_links(path):
    for target in links(path.read_text()):
        parsed = urlsplit(target)
        if parsed.scheme or parsed.netloc:
            continue
        destination = path.parent / unquote(parsed.path) if parsed.path else path
        yield target, destination.resolve(), unquote(parsed.fragment)


def validate_document(path, root):
    errors = []
    label = path.relative_to(root)
    try:
        for target, destination, fragment in local_links(path):
            if target.startswith('/') or not destination.is_relative_to(root):
                errors.append(f'{label}: local link must stay relative to the repository: {target}')
            elif not destination.exists():
                errors.append(f'{label}: missing link: {target}')
            elif fragment and destination.suffix == '.md' and fragment not in anchors(destination.read_text()):
                errors.append(f'{label}: missing fragment: {target}')
    except ValueError as error:
        errors.append(f'{label}: {error}')
    if HOME_PATH.search(path.read_text()):
        errors.append(f'{label}: machine-specific home path')
    return errors


def personal_skills(root):
    """Skills listed in the skills index: the ones maintained here, not installed by a tool."""
    index = root / '.agents/skills/INDEX.md'
    if not index.is_file():
        return []
    names = (SKILL_LINK.fullmatch(target) for target in links(index.read_text()))
    return [root / '.agents/skills' / match.group(1) for match in names if match]


def validate_navigation(root, documents):
    entry = root / '.agents/AGENTS.md'
    reached = set()
    pending = [entry]
    while pending:
        page = pending.pop()
        if page in reached or not page.is_file():
            continue
        reached.add(page)
        try:
            pending.extend(destination for _, destination, _ in local_links(page) if destination in documents)
        except ValueError:
            continue
    return [f'{page.relative_to(root)}: unreachable from the global entry point'
            for page in sorted(documents - reached)]


def validate_index(path, root):
    errors = []
    for line in path.read_text().splitlines():
        if not line.startswith('|') or line.startswith('| ---') or 'Open when |' in line:
            continue
        cells = [cell.strip() for cell in line.strip('|').split('|')]
        if len(cells) != 2 or not INLINE_LINK.fullmatch(cells[0]) or len(WORD.findall(cells[-1])) < 3:
            errors.append(f'{path.relative_to(root)}: index row needs one link and a useful trigger')
    return errors


def validate(root):
    root = root.resolve()
    skills = personal_skills(root)
    documents = {root / 'AGENTS.md', root / 'CLAUDE.md', root / '.agents/AGENTS.md', root / '.agents/skills/INDEX.md'}
    documents |= set((root / '.agents/knowledge').rglob('*.md'))
    for skill in skills:
        documents |= set(skill.rglob('*.md'))
    errors = []
    for required in ('AGENTS.md', 'CLAUDE.md', '.agents/AGENTS.md', '.agents/knowledge/INDEX.md',
                     '.agents/skills/INDEX.md'):
        if not (root / required).is_file():
            errors.append(f'{required}: required entry point missing')
    for path in sorted(documents):
        if path.is_file():
            errors.extend(validate_document(path, root))
    errors.extend(validate_navigation(root, documents))
    for path in sorted(documents):
        if not path.is_file():
            continue
        limit = None
        if path.name == 'INDEX.md':
            errors.extend(validate_index(path, root))
            limit = INDEX_WORDS
        elif path == root / '.agents/AGENTS.md':
            limit = ENTRY_WORDS
        elif path.name == 'SKILL.md':
            limit = 1200
        if limit and len(WORD.findall(path.read_text())) > limit:
            errors.append(f'{path.relative_to(root)}: exceeds {limit}-word entry-point budget')
    for skill in skills:
        try:
            if skill.is_symlink():
                raise ValueError('personal source must be a real directory')
            read_manifest(skill)
        except (OSError, ValueError) as error:
            errors.append(f'{skill.relative_to(root)}: {error}')
    return errors, len(documents)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT, help='repository root to validate')
    args = parser.parse_args()
    errors, count = validate(args.root)
    if errors:
        print('\n'.join(errors), file=sys.stderr)
        return 1
    print(f'Validated {count} Markdown files, navigation, fragments, budgets, and skill manifests.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
