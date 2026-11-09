# Claude Code

Use the [managents skill](../../skills/managents/SKILL.md) for installation and checks.

| Resource | Destination |
| --- | --- |
| Global instructions | `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/CLAUDE.md` |
| Personal skills | `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/NAME` |

`CLAUDE_CONFIG_DIR` selects a different configuration directory. Use the same
value for installation and launch. See the official [environment variables](https://code.claude.com/docs/en/env-vars)
and [skill discovery](https://code.claude.com/docs/en/skills) documentation.

Project `AGENTS.md` loading depends on Claude Code's version and instruction
settings. Versions before 2.1.277 load `CLAUDE.md` instead. The shared entry point
therefore explicitly asks the agent to read applicable project instructions.
This is an instruction to the model, not automatic file injection. For guaranteed
loading in an older installation, a project's `CLAUDE.md` can import `@AGENTS.md`;
keep the policy in `AGENTS.md`. Newer releases have a configurable AGENTS loader.
See [instruction discovery and compatibility](https://code.claude.com/docs/en/memory).
This repository includes that [import bridge](../../../CLAUDE.md), so its project
constraints load in older installations without a second policy copy.

In a fresh session, use `/memory` to inspect instruction sources and the skill
menu to confirm personal skill names. Check `/config` when the version supports
project instruction selection. Safe or minimal launch modes can disable normal
instruction discovery; a correct symlink alone cannot override those modes.
When selecting `--setting-sources`, include `user` for these personal skills.

Native agents and plugin skills remain provider-owned. The shared authoring
workflow does not invoke Claude-specific evaluators or assume a Claude model ID
when running in another provider.
