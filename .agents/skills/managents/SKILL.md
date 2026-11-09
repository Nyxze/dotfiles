---
name: managents
description: Manage the shared agent configuration in ~/.agents with the managents command. Use to list skills and their scope, make an agent's skill global so every agent gets it, link a new shared skill or instruction file to each agent, or check why an agent does not see a shared skill. Not for provider plugins or built-in skills.
---

# managents

`~/.agents` is the global context fed into every agent session: `AGENTS.md`, `skills/` and `docs/`. It is a symlink to
`.agents/` in the dotfiles repository, so editing there edits the repository. Each agent reaches it through symlinks, and
the `managents` command owns those links. Run `managents --help` for the exact syntax.

## Look before acting

1. `managents skills ls --json` lists every skill with its scope: `global` (in `~/.agents/skills`, shared) or the name of
   the agent that owns it. Per agent, the state is `linked`, `missing`, `copy`, `differs`, `own` or `native`.
2. `managents status --json` gives the entry files, the docs link and the skills per agent. Use it to find out why an
   agent does not see something.
3. `managents check` exits 1 when something is not linked.

## Make a skill global

Use it when a skill that only one agent holds should be available to all of them.

1. Find it with `managents skills ls`; the scope names the agent that owns it.
2. Run `managents skills promote NAME global --dry-run` and read the plan, then run it without `--dry-run`. The agent's
   folder is backed up, moved into `~/.agents/skills/NAME`, and every agent is linked to it.
3. When the copies held by several agents differ, the command stops and asks for `--from AGENT`. Ask the user which copy
   wins; do not pick one.

## Add shared context

- A new shared instruction, skill or knowledge page goes under `~/.agents`, never in an agent's own folder
  (`~/.claude`, `~/.codex`, `~/.config/opencode`) and never copied into several places.
- After adding a skill folder, run `managents setup --dry-run`, then `managents setup`, so each agent gets its link.
- A skill that only one agent can use stays in that agent's own skills folder: leave it alone and do not promote it.

## Create a skill

- Create the skill folder in `~/.agents/skills/NAME/`, never in an agent's own folder: `SKILL.md` with a `name` equal to the
  folder name and a `description`. Then run `managents setup --dry-run` and `managents setup` so each agent gets its link.
- For the authoring workflow itself (what to put in the skill, how to test it), use the `skill-creator` skill.
- A tool that writes into an agent's own skills folder by default leaves an agent-owned skill: run
  `managents skills promote NAME global` to make it shared.

## Rules

- A conflict (exit code 1) means the command wrote nothing. Report its message; never resolve it by linking, moving or
  deleting files by hand. `--force` backs up and replaces what conflicts: use it only when the user agrees.
- The command does not commit. Changes show up in the dotfiles repository as untracked or modified files; commit them only
  when asked.
- If `managents` is not found, `~/.local/bin/managents` is missing: it is a symlink to `scripts/managents` in the dotfiles
  repository, created by `managents setup`.
