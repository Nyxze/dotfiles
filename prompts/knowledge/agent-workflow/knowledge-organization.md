# Knowledge organization

This contract governs shared agent knowledge in this repository. It adapts the
[Notion knowledge-organization contract](https://app.notion.com/p/3fd68c4ebcd281c0a7efc45f992f2641)
to repository files; the Notion page remains the authority for Notion workspaces.

## Ownership

Every durable rule, fact, definition, and procedure has one canonical owner.
Other files link to that owner with a short navigation label; they do not copy
its substance or maintain a parallel summary. Search for an owner before adding
a page. Update the existing owner when the subject has the same identity. Link
external sources from that owner; do not create translated or mirrored policies.

| Resource | Owns |
| --- | --- |
| [Global `AGENTS.md`](../AGENTS.md) | Instructions needed in every session and the route to task-specific context. |
| [Knowledge indexes](../INDEX.md) | Relative links and concise triggers, without procedures or policy text. |
| Topic references | One subject's current rules, contracts, or procedures. |
| [Installation index](../../MAIN.md) | Shared installation, capture, and repair commands. |
| [Provider guides](../../providers/) | Destinations and behavior unique to each provider. |
| [Personal skills](../../skills/INDEX.md) | Bounded, repeatable task workflows; they link to standing rules. |
| [Agent definitions](../../agents/) | Optional provider roles and tool settings, never shared policy. |
| [Adapters](../../adapters/) and [scripts](../../../scripts/) | Executable behavior; documentation links to them for implementation detail. |
| [Repository `AGENTS.md`](../../../AGENTS.md) | Constraints specific to that repository or subtree. |

## Context and maintenance

- Read from broad context to the owner of the task: global instructions, local
  repository instructions, topical index, then the relevant reference or skill.
  Local instructions add constraints without restating inherited ones. A link
  alone does not guarantee an agent loaded its target.
- Resolve a conflict at its canonical owner before editing dependent pages.
  Keep a current rule separate from its Git history; historical documents do
  not override the current owner.
- Decide skill ownership before capture. Provider-owned skills stay with the
  provider; capture a personal reusable skill into the shared source during the
  same task, then install it through the [installation index](../../MAIN.md).
- When moving or changing an owner, update inbound references and related
  installation behavior in the same change. Run `scripts/validate-prompts.py`
  from the repository root and check the affected provider links or scripts.
- Keep global and index pages short. The validator budgets these entry points;
  move detail to its owner before raising a limit. Long references and skills
  remain acceptable when their task requires the detail.
