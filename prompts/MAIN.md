# Installation index

Run commands from the dotfiles repository root. This page covers installation
and repair.

| Resource | Installation role | Open when |
| --- | --- | --- |
| [Global instructions](knowledge/AGENTS.md) | One source linked into all providers and the home entry point. | Changing global preferences or repairing instruction links. |
| [Personal skills](skills/INDEX.md) | One shared skill directory linked per skill into each provider. | Installing or capturing a personal reusable workflow. |
| [Agent definitions](agents/) | Provider agent source; currently empty. | Adding an agent for Claude Code and OpenCode. |
| [Codex guide](providers/codex/install.md) | Provider-specific destinations and behavior. | Installing or repairing Codex. |
| [Claude Code guide](providers/claude-code/install.md) | Provider-specific destinations and behavior. | Installing or repairing Claude Code. |
| [OpenCode guide](providers/opencode/install.md) | Provider-specific destinations and conversion. | Installing or repairing OpenCode. |

`./scripts/install.sh` installs global instructions, personal skills, and any
agent definitions. `./prompts/link-knowledge.sh` repairs only the instruction
links. A conflicting instruction file is left in place unless `--force` backs
it up under `$XDG_STATE_HOME/dotfiles/knowledge-backups/`.

`./scripts/install-skills.sh --provider all` links only personal skills. Omit
`--provider` in a terminal for an interactive provider menu. Existing
provider-owned skills remain in place; a conflicting personal skill stops the
link unless `--force` backs it up under
`$XDG_STATE_HOME/dotfiles/skill-backups/`.
A personal skill is a directory with `SKILL.md`; its `name` must match the
directory name.

`./prompts/capture.sh PROVIDER` captures provider-written agents and checks
existing shared skills for conflicts. To import a new personal skill, name it
explicitly: `./prompts/capture.sh --skill NAME PROVIDER`. Other new provider
skills remain in place. Reconcile conflicting edits manually before linking
them again.

Run `./scripts/validate-prompts.py` after editing documentation or skills to
check links, navigation, entry-point budgets, portable paths, and skill names.
