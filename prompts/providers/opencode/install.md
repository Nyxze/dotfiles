# OpenCode

`scripts/install.sh` writes both destinations from `prompts/`. There is no
symlink and no intermediate directory.

```bash
./scripts/install.sh opencode
```

| Source            | Destination                  | How        |
| ----------------- | ---------------------------- | ---------- |
| `prompts/skills/` | `~/.config/opencode/skills/` | copied     |
| `prompts/agents/` | `~/.config/opencode/agent/`  | converted  |

**Not `~/.opencode/skills`.** OpenCode reads `.opencode/skills` relative to the
working directory, walking up as far as the git worktree; the only global
location it scans is `~/.config/opencode/skills`. Skills installed under
`~/.opencode` therefore load only while the working directory happens to be the
home directory itself, which is why they look installed and are not.

A skill is a directory holding a `SKILL.md`, and the directory name has to match
the `name` in that file's front matter.

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
