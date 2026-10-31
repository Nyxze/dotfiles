# Installation Index

`prompts/knowledge/AGENTS.md` is the single source for global working preferences.
`scripts/install.sh` links it to each provider's global instruction file, so
edits from any tool reach the same source immediately. It backs up existing
global instruction files under `$XDG_STATE_HOME/dotfiles/knowledge-backups/`
when run with `--force`; without `--force`, a conflicting file stops the link.
Run `./prompts/link-knowledge.sh` to install only these links.

`prompts/skills/` holds personal skills once. `scripts/install.sh` links each
skill directory into Codex, Claude Code, and OpenCode. Existing provider-owned
skills remain in place. A conflicting skill stops the link unless `--force`
backs it up under `$XDG_STATE_HOME/dotfiles/skill-backups/`. New skills created
by a tool can be imported with `./prompts/capture.sh PROVIDER`, then linked
with `./scripts/install-skills.sh --provider all`. Conflicting skill changes
require manual review.

For skills only, run `./scripts/install-skills.sh`. It asks which provider to
install for in a terminal; `--provider all` links to all three without a prompt.
Repeat `--provider` to target a subset. This command does not install agents,
global instructions, packages, or desktop configuration.

`prompts/agents/` holds provider agents. `scripts/install.sh` copies or converts
those for Claude Code and OpenCode. `capture.sh` brings back agents a tool wrote
on its own; `providers.sh` names the provider directories.

| Provider | Install Instructions |
|----------|---------------------|
| Codex | [providers/codex/install.md](providers/codex/install.md) |
| Claude Code | [providers/claude-code/install.md](providers/claude-code/install.md) |
| OpenCode | [providers/opencode/install.md](providers/opencode/install.md) |
