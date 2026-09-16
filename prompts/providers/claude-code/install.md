# Claude Code

`scripts/install.sh` copies straight from `prompts/`. There is no symlink and no
intermediate directory.

```bash
./scripts/install.sh claude-code
```

| Source            | Destination         |
| ----------------- | ------------------- |
| `prompts/skills/` | `~/.claude/skills/` |
| `prompts/agents/` | `~/.claude/agents/` |

A skill is a directory holding a `SKILL.md`, and the directory name has to match
the `name` in that file's front matter.

skill-creator writes new skills into `~/.claude/skills` rather than here, so the
copy refuses while that directory holds something `prompts/` does not.
`./prompts/capture.sh claude-code` brings it back first; `--force` discards it.
