# Shared agent instructions

This is the shared instruction source for Codex, Claude Code, and OpenCode.
Read the applicable project `AGENTS.md` and any instructions in the directories
you work in, even when the provider does not load that filename automatically.
Project instructions specialize these defaults; current user instructions take
precedence over durable preferences.

Start at the [knowledge index](INDEX.md) and open the owners relevant to the
task. Resolve this file and installed skills to their real paths before following
relative links. `readlink -f "$HOME/AGENTS.md"` locates this source on an installed
machine; links are relative to the canonical file, not its provider alias.

Write all artifacts in English. Reply in the user's language.
Use short, technical prose; report the result and decisions needed, without
process narration, flattery, or apologies. When challenged, state the reasoning
before revising it. Leave user-owned decisions to the user.

Keep project constraints in the project's instructions. Record durable personal
preferences in their existing knowledge owner during the same task, never as
conversation history. Keep model, permission, and feature settings in provider
configuration. Read [maintenance](maintenance.md) before changing this system.

For machine changes, follow [managed configuration](machine.md) and edit the
repository source before deploying. Never leave a live-only fix.

Prefer an existing personal skill when it fits.
Prefer maintained scripts or CLIs for repeatable operations; turn a command
sequence needed twice into a script with explicit inputs and outputs.
