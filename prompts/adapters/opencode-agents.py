#!/usr/bin/env python3
"""Claude Code agents -> opencode agents.

opencode rejects its whole configuration over a single malformed agent file,
and a Claude front matter is malformed to it: `tools` is a comma-separated
string where opencode wants a map. `model` is worse than malformed — the value
`sonnet` passes validation and resolves to an empty model, so a copied agent
loads cleanly and only fails once something runs it. Hence a translation rather
than a copy.

The destination is generated: it is written from prompts/agents, never read
back. Only the files listed in the manifest are removed, so a hand-written
opencode agent sitting in the same directory survives.

Usage: opencode-agents.py <source dir> <destination dir>
"""

import sys
from pathlib import Path

import yaml

MANIFEST = ".generated-from-prompts"

# Claude's `tools` is an allowlist: what it does not name is denied. opencode's
# map runs the other way, everything allowed until set false, so the conversion
# opens on a wildcard denial and turns back on only what was named — which also
# leaves a tool opencode adds later denied rather than silently granted.
TOOLS = {
    "Read": "read",
    "Write": "write",
    "Edit": "edit",
    "Bash": "bash",
    "Glob": "glob",
    "Grep": "grep",
    "WebFetch": "webfetch",
    "Task": "task",
    "TodoWrite": "todowrite",
    "Skill": "skill",
}

# Keyed on what `opencode models` actually lists. A shorthand missing from here
# is dropped rather than guessed at, which leaves opencode on its own default
# instead of on a model id that resolves to nothing.
MODELS = {
    "sonnet": "openrouter/anthropic/claude-sonnet-5",
    "opus": "openrouter/anthropic/claude-opus-4.5",
    "haiku": "openrouter/anthropic/claude-haiku-4.5",
}


def warn(message):
    print(f"  ! {message}", file=sys.stderr)


def split_front_matter(text):
    if not text.startswith("---\n"):
        return None, text
    end = text.find("\n---\n", 3)
    if end == -1:
        return None, text
    return yaml.safe_load(text[4:end]) or {}, text[end + 5 :]


def convert_tools(spec, name):
    named = [t.strip() for t in str(spec).split(",") if t.strip()]
    tools = {"*": False}
    for tool in named:
        if tool not in TOOLS:
            warn(f"{name}: no opencode equivalent for {tool}, left denied")
            continue
        tools[TOOLS[tool]] = True
    return tools


def convert(meta, body, name):
    out = {}

    description = meta.get("description")
    if description:
        out["description"] = description
    else:
        warn(f"{name}: no description, opencode will not show it in the picker")

    # Claude agents are all delegated to, never driven directly.
    out["mode"] = "subagent"

    model = meta.get("model")
    if model in MODELS:
        out["model"] = MODELS[model]
    elif model:
        warn(f"{name}: unmapped model {model!r}, falling back to opencode's default")

    # An absent `tools` means every tool in both formats, so the key is left out
    # rather than spelled as a map that allows everything.
    if meta.get("tools"):
        out["tools"] = convert_tools(meta["tools"], name)

    front = yaml.safe_dump(out, sort_keys=False, allow_unicode=True, width=10**6)
    return f"---\n{front}---\n{body.lstrip(chr(10))}"


def main(source, destination):
    destination.mkdir(parents=True, exist_ok=True)
    manifest = destination / MANIFEST
    previous = set(manifest.read_text().split()) if manifest.exists() else set()

    written = set()
    for path in sorted(source.glob("*.md")):
        meta, body = split_front_matter(path.read_text())
        if meta is None:
            warn(f"{path.name}: no front matter, not an agent — skipped")
            continue
        (destination / path.name).write_text(convert(meta, body, path.name))
        written.add(path.name)

    for stale in previous - written:
        (destination / stale).unlink(missing_ok=True)

    manifest.write_text("\n".join(sorted(written)) + "\n")
    print(f"{len(written)} converted", end="")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__.strip().splitlines()[-1])
    sys.exit(main(Path(sys.argv[1]), Path(sys.argv[2])))
