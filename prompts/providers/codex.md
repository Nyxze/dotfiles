# Codex

Use the [resource guide](../README.md) for installation and checks.

| Resource | Destination |
| --- | --- |
| Global instructions | `${CODEX_HOME:-$HOME/.codex}/AGENTS.md` |
| Personal skills | `$HOME/.agents/skills/NAME` |

`CODEX_HOME` moves Codex's config and instruction directory; it does not move
this installation's user skill directory. Provider-managed system skills remain
separate. These paths follow the official [instruction discovery](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
and [local skill discovery](https://learn.chatgpt.com/docs/build-skills) contracts.

A nonempty `AGENTS.override.md` in the config directory takes precedence over
`AGENTS.md`; the resource command reports this shadow instead of deleting it.
Project discovery starts at the repository root and proceeds toward the current
working directory, selecting at most one instruction file per directory.
`~/AGENTS.md` is a source locator, not a substitute for the global config target.

Start a fresh session after changing discovery paths. Check the skill selector
or the app-server `skills/list` result for each personal skill and its canonical
path. Duplicate names can both appear; the shared authoring skill is named
`maintain-skills` to avoid colliding with the built-in `skill-creator`.

The filesystem check cannot detect every launch flag, project override, plugin,
or instruction-size setting. If behavior differs, inspect the active config and
which instruction files the session loaded before changing shared policy.
