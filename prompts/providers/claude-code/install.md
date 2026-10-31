# Claude Code

From the repository root, `scripts/install.sh` links skills and global
instructions from `prompts/`. It copies provider agents when definitions exist.
The global instruction target is `~/.claude/CLAUDE.md`.

```bash
./scripts/install.sh claude-code
```

| Source            | Destination         |
| ----------------- | ------------------- |
| `prompts/skills/` | `~/.claude/skills/<name>` (per-skill symlink) |
| `prompts/agents/` | `~/.claude/agents/` (currently no definitions) |
| `prompts/knowledge/AGENTS.md` | `~/.claude/CLAUDE.md` (symlink) |
