---
name: maintain-skills
description: Create, revise, or review personal skills shared by Codex, Claude Code, and OpenCode in the dotfiles repository. Use for maintaining these workflows, their resources, and task triggers; provider and plugin skills stay with their owner.
---

# Maintain personal skills

Resolve this file to its canonical path. Follow the shared
[maintenance rules](../../knowledge/maintenance.md); the
[managents skill](../managents/SKILL.md) owns linking, listing and promotion commands.

Establish the intended task, expected output, and cases where the skill should
not run. Use the current request and existing workflow before asking for missing
information. Inspect the existing skill, its resources, and callers before
removing or replacing anything.

Keep the shared skill under `.agents/skills/NAME/`. `SKILL.md` starts with YAML
`name` and `description`; the name matches the directory and uses lowercase
letters, digits, and single hyphens (at most 64 characters). Describe the actual
task and trigger in 1–1024 characters. The shared validator owns these checks.

Write the decisions and steps another agent needs to execute the task. Link to
standing rules rather than copying them. Keep tools and models provider-neutral;
put provider requirements in provider documentation. Do not add compulsory
interviews, approval rounds, or benchmarks where the task already supplies the
needed authority and information.

Use supporting resources only when they have a concrete consumer:

- `references/` holds conditional detail, linked with a reading trigger.
- `scripts/` holds repeated deterministic work with explicit inputs, outputs,
  dependencies, and failure behavior.
- `assets/` holds files used in outputs. Preserve third-party attribution and
  licenses when importing material.

Keep generated packages, evaluation output, and caches outside the source skill.
Avoid names that collide with provider-supplied skills. A rename must update the
skill index and inbound links and remove old managed links with `managents setup`.

Validate with `./scripts/validate-agents.py` and the tests of the dotfiles repository. For a changed workflow, walk
through a realistic request, a nearby request that should not trigger it, and a
failure or missing-input case. Run changed scripts in an isolated fixture and
check observable outcomes. If testing through a provider, use that provider's
installed tools and report what actually ran; metadata checks alone do not prove
behavior. Reserve comparative model evaluations for changes that need them.

Run `managents setup` and `managents check` after validation. Report remaining
limitations without claiming unrun provider or model tests.
