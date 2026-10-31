# OpenCode

`scripts/install.sh` links personal skills and global instructions from
`prompts/`. It converts provider agents. The global instruction target is
`~/.config/opencode/AGENTS.md`.

```bash
./scripts/install.sh opencode
```

| Source            | Destination                  | How        |
| ----------------- | ---------------------------- | ---------- |
| `prompts/skills/` | `~/.config/opencode/skills/<name>` | per-skill symlink |
| `prompts/agents/` | `~/.config/opencode/agent/`  | converted  |
| `prompts/knowledge/AGENTS.md` | `~/.config/opencode/AGENTS.md` | symlink |

**Not `~/.opencode/skills`.** The native global location is
`~/.config/opencode/skills`. OpenCode also scans the Claude and agent-compatible
global directories, but the explicit native links keep its installation
independent of those providers.

A skill is a directory holding a `SKILL.md`, and the directory name has to match
the `name` in that file's front matter.
If OpenCode writes a new skill under its global skills directory, run
`./prompts/capture.sh opencode` and
`./scripts/install-skills.sh --provider all` to share it.

Agents are converted, by `adapters/opencode-agents.py`, because opencode reads
a front matter of its own — note the directory is `agent/`, singular:

| Claude Code                    | opencode                                     |
| ------------------------------ | -------------------------------------------- |
| `name:`                        | dropped — the filename carries it             |
| `tools: Read, Write`           | `tools: {'*': false, read: true, write: true}` |
| `model: sonnet`                | a full `provider/model` id                    |
| —                              | `mode: subagent`                              |

Two of those carry weight. `tools` is an allowlist in Claude and allow-unless-
denied in opencode, so the conversion opens on a wildcard denial and re-grants only
what was named; a tool opencode adds later stays denied instead of being handed
over silently. And `model: sonnet` is not rejected by opencode — it resolves to
an empty model, so a copied agent loads cleanly and fails only once something
runs it. The shorthands are mapped in the adapter's `MODELS` table against what
`opencode models` lists.

That directory is generated: it is written from `prompts/agents/` and never read
back, so `capture.sh` skips it and an edit made there is lost on the next
install. Agents written by hand are left alone — the adapter removes only what
it previously wrote, tracked in `.generated-from-prompts`.
