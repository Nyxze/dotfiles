# Codex

From the repository root, `scripts/install.sh codex` links `~/.codex/AGENTS.md` to
`prompts/knowledge/AGENTS.md`. It also links `~/AGENTS.md` to the same source,
so tools that discover parent instructions from the home directory see the same
preferences.

It links each directory in `prompts/skills/` under `~/.agents/skills/`, which
Codex scans. Codex's own `.system` skills remain separate.

```bash
./scripts/install.sh codex
```
