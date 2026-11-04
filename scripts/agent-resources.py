#!/usr/bin/env python3
"""Install, inspect, and import shared agent resources without directory mirroring."""

import argparse
from dataclasses import dataclass
import os
from pathlib import Path
import shutil
import sys
import tempfile

from lib.skill_manifest import NAME, read_manifest


ROOT = Path(__file__).resolve().parents[1]
PROVIDERS = ("codex", "claude-code", "opencode")


def environment_path(name, default):
    path = Path(os.environ.get(name) or default).expanduser()
    if not path.is_absolute():
        raise ValueError(f"{name} must be an absolute path: {path}")
    return path


def destinations():
    home = Path.home()
    codex = environment_path("CODEX_HOME", home / ".codex")
    claude = environment_path("CLAUDE_CONFIG_DIR", home / ".claude")
    config = environment_path("XDG_CONFIG_HOME", home / ".config")
    return {
        "home": (home / "AGENTS.md", None),
        "codex": (codex / "AGENTS.md", home / ".agents/skills"),
        "claude-code": (claude / "CLAUDE.md", claude / "skills"),
        "opencode": (config / "opencode/AGENTS.md", config / "opencode/skills"),
    }


def exists(path):
    return path.exists() or path.is_symlink()


def linked_to(target, source):
    return target.is_symlink() and target.resolve() == source


def personal_skills(root):
    directory = root / "prompts/skills"
    skills = []
    for path in sorted(directory.iterdir()):
        if path.name.startswith(".") or not path.is_dir():
            continue
        if path.is_symlink():
            raise ValueError(f"personal skill source must be a real directory: {path}")
        read_manifest(path)
        skills.append(path)
    return skills


@dataclass(frozen=True)
class Link:
    target: Path
    source: Path


def selected_providers(names):
    if "all" in names and len(names) != 1:
        raise ValueError("select all by itself")
    return list(dict.fromkeys(PROVIDERS if not names or names == ["all"] else names))


def link_plan(root, providers, only):
    targets = destinations()
    skills = personal_skills(root) if only != "instructions" else []
    links = []
    stale = []
    if only != "skills":
        source = root / "prompts/knowledge/AGENTS.md"
        if not source.is_file() or not source.read_text().strip():
            raise ValueError(f"missing or empty global instructions: {source}")
        for provider in dict.fromkeys(["home", *providers]):
            links.append(Link(targets[provider][0], source))
    if only != "instructions":
        for provider in providers:
            directory = targets[provider][1]
            if directory is None:
                continue
            links.extend(Link(directory / skill.name, skill) for skill in skills)
            if directory.is_dir():
                for path in directory.iterdir():
                    if path.is_symlink() and path.resolve().parent == root / "prompts/skills":
                        if path.resolve() not in skills:
                            stale.append(path)
    by_target = {}
    for link in links:
        target = link.target.parent.resolve() / link.target.name
        if target in by_target and by_target[target] != link.source:
            raise ValueError(f"destinations overlap: {link.target}")
        by_target[target] = link.source
    stale = {path.parent.resolve() / path.name for path in stale}
    for target in [*by_target, *stale]:
        if target.parent.resolve().is_relative_to(root):
            raise ValueError(f"destination would modify the source checkout: {target}")
        if any(parent in by_target for parent in target.parents):
            raise ValueError(f"destinations overlap: {target}")
    return [Link(t, s) for t, s in by_target.items()], sorted(stale)


def instruction_shadows(providers, only):
    if only == "skills" or "codex" not in providers:
        return []
    override = destinations()["codex"][0].with_name("AGENTS.override.md")
    if override.is_file() and override.read_text().strip():
        return [f"{override} shadows the shared Codex instructions; reconcile it manually"]
    return []


def inspect_links(links, stale, providers, only):
    errors = instruction_shadows(providers, only)
    for link in links:
        if not linked_to(link.target, link.source):
            errors.append(f"{link.target}: expected symlink to {link.source}")
    errors.extend(f"{path}: stale shared skill link" for path in stale)
    if errors:
        raise ValueError("\n".join(errors))
    print(f"Checked {len(links)} instruction and skill links; no stale links or known shadows.")


def install(links, stale, providers, args):
    errors = instruction_shadows(providers, args.only)
    changes = []
    for link in links:
        if linked_to(link.target, link.source):
            continue
        for parent in link.target.parents:
            if exists(parent) and not parent.is_dir():
                errors.append(f"{parent}: destination parent is not a directory")
                break
        if exists(link.target) and not args.force:
            errors.append(f"{link.target}: already exists; reconcile it or use --force to back it up")
        changes.append(link)
    if errors:
        raise ValueError("\n".join(errors))
    backup_root = environment_path("XDG_STATE_HOME", Path.home() / ".local/state") / "dotfiles/agent-backups"
    batch = None
    for link in changes:
        if args.dry_run:
            action = "back up and link" if exists(link.target) else "link"
            print(f"Would {action}: {link.target} -> {link.source}")
            continue
        link.target.parent.mkdir(parents=True, exist_ok=True)
        if exists(link.target):
            if batch is None:
                backup_root.mkdir(parents=True, exist_ok=True)
                batch = Path(tempfile.mkdtemp(prefix="install-", dir=backup_root))
            backup = batch / str(len(list(batch.iterdir()))) / link.target.name
            backup.parent.mkdir()
            shutil.move(str(link.target), str(backup))
            print(f"Backed up {link.target} to {backup}")
        link.target.symlink_to(link.source, target_is_directory=link.source.is_dir())
        print(f"Linked {link.target} -> {link.source}")
    for path in stale:
        if args.dry_run:
            print(f"Would remove stale shared skill link: {path}")
        else:
            path.unlink()
            print(f"Removed stale shared skill link: {path}")
    print(f"{'Planned' if args.dry_run else 'Installed'} {len(changes)} links; {len(stale)} stale links.")


def tree_bytes(directory):
    files = {}
    for path in directory.rglob("*"):
        if path.is_symlink() or (not path.is_dir() and not path.is_file()):
            raise ValueError(f"unsupported resource in imported skill: {path}")
        if path.is_file():
            files[path.relative_to(directory)] = (path.read_bytes(), path.stat().st_mode & 0o111)
    return files


def capture(root, args):
    source_root = destinations()[args.provider][1]
    planned = []
    for name in dict.fromkeys(args.skill):
        if not NAME.fullmatch(name) or len(name) > 64:
            raise ValueError(f"invalid skill name: {name}")
        source = source_root / name
        target = root / "prompts/skills" / name
        if not source.is_dir():
            raise ValueError(f"skill not found: {source}")
        read_manifest(source)
        if source.resolve() == target:
            print(f"Already shared: {name}")
            continue
        contents = tree_bytes(source)
        if exists(target):
            if target.is_dir() and not target.is_symlink() and tree_bytes(target) == contents:
                print(f"Already matches: {name}")
                continue
            raise ValueError(f"{source} differs from {target}; merge manually (capture never overwrites)")
        planned.append((source, target))
    for source, target in planned:
        if args.dry_run:
            print(f"Would capture {source} -> {target}")
            continue
        with tempfile.TemporaryDirectory(prefix=".capture-", dir=target.parent) as temporary:
            staged = Path(temporary) / target.name
            shutil.copytree(source, staged, symlinks=True)
            tree_bytes(staged)
            read_manifest(staged)
            staged.rename(target)
        print(f"Captured {source} -> {target}; add it to prompts/skills/INDEX.md")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ("install", "check"):
        command = commands.add_parser(name, help="link shared resources" if name == "install" else "check live links and overrides")
        command.add_argument("providers", nargs="*", metavar="PROVIDER",
                             help="codex, claude-code, opencode, home, or all (default: all)")
        command.add_argument("--only", choices=("instructions", "skills"))
        if name == "install":
            command.add_argument("--force", action="store_true", help="back up conflicting destinations before linking")
            command.add_argument("--dry-run", action="store_true", help="validate and show changes without writing")
    command = commands.add_parser("capture", help="import explicitly named personal skills; never overwrite")
    command.add_argument("provider", choices=PROVIDERS)
    command.add_argument("--skill", action="append", required=True, help="skill name to import (repeatable)")
    command.add_argument("--dry-run", action="store_true")
    args = parser.parse_args(argv)
    try:
        if args.command == "capture":
            capture(ROOT, args)
            return 0
        if any(name not in (*PROVIDERS, "home", "all") for name in args.providers):
            parser.error("unknown provider; choose codex, claude-code, opencode, home, or all")
        if "all" in args.providers and len(args.providers) != 1:
            parser.error("select all by itself")
        if "home" in args.providers and args.only == "skills":
            parser.error("home is an instruction target, not a skill provider")
        providers = selected_providers(args.providers)
        links, stale = link_plan(ROOT, providers, args.only)
        if args.command == "check":
            inspect_links(links, stale, providers, args.only)
        else:
            install(links, stale, providers, args)
    except (OSError, ValueError, RuntimeError) as error:
        print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
