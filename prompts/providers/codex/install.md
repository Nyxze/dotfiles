# Codex

`scripts/install.sh codex` links `~/.codex/AGENTS.md` to
`prompts/knowledge/AGENTS.md`. It also links `~/AGENTS.md` to the same source,
so tools that discover parent instructions from the home directory see the same
preferences. The link installer backs up a conflicting file when passed
`--force` and otherwise leaves it untouched.

It links each directory in `prompts/skills/` under `~/.agents/skills/`, which
Codex scans. Codex's own `.system` skills remain separate.
If Codex writes a new skill under `~/.codex/skills/`, run
`./prompts/capture.sh codex` and `./scripts/install.sh` to share it.

```bash
./scripts/install.sh codex
```

Repository instructions stay in each repository's `AGENTS.md`.
