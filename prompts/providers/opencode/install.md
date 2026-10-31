# OpenCode

From the repository root, `scripts/install.sh` links personal skills and global
instructions from `prompts/`. It converts provider agents when definitions
exist. The global instruction target is
`~/.config/opencode/AGENTS.md`.

```bash
./scripts/install.sh opencode
```

| Source            | Destination                  | How        |
| ----------------- | ---------------------------- | ---------- |
| `prompts/skills/` | `~/.config/opencode/skills/<name>` | per-skill symlink |
| `prompts/agents/` | `~/.config/opencode/agent/`  | converted when defined |
| `prompts/knowledge/AGENTS.md` | `~/.config/opencode/AGENTS.md` | symlink |

**Not `~/.opencode/skills`.** The native global location is
`~/.config/opencode/skills`. OpenCode also scans the Claude and agent-compatible
global directories, but the explicit native links keep its installation
independent of those providers.

The [agent adapter](../../adapters/opencode-agents.py) converts Claude Code
front matter to OpenCode's format. It tracks generated names in
`.generated-from-prompts`, so hand-written agents in `agent/` remain untouched.
Generated files are not captured back into the shared source.
