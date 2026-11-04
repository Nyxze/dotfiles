# Maintaining agent resources

The system has two entry points: [global instructions](AGENTS.md) for agents
doing work, and the [resource guide](../README.md) for installation and repair.
Both lead to the same canonical sources. A Markdown link routes a reader; it
does not cause a provider to load the target automatically.

## Ownership

| Resource | Owns |
| --- | --- |
| Global instructions | Cross-project preferences and the route to task context. |
| Knowledge index | Links with short task triggers. |
| Topic reference | One subject's standing rules or procedure. |
| Personal skill | A bounded workflow selected by its name and description. |
| Resource guide | Installation, capture, verification, and recovery commands. |
| Provider guide | Provider-specific discovery, precedence, and diagnostics. |
| Project `AGENTS.md` | Constraints of that project or subtree. |
| Scripts and tests | Executable behavior and regression checks. |

Apply the shared [ownership rule](development.md#ownership) using the resource
table above. Short navigation descriptions are useful, but a second policy,
translated copy, or competing procedure is not. Keep current rules self-contained;
external documentation supports provider facts rather than defining personal
policy. Git retains historical decisions.

Keep reusable knowledge separate from session transcripts, temporary plans,
benchmark output, packaged archives, credentials, and provider caches. Preserve
established personal preferences when reorganizing them. Do not turn a proposed
improvement into a new user preference without evidence from the user's request.

## Changing the system

1. Read the owner and search its inbound links and script callers. Decide whether
   the change belongs in shared knowledge, a project, a skill, or provider config.
2. Edit the repository source. Resolve installed symlinks before reading relative
   links or editing. Personal skills are maintained here; provider and plugin
   skills stay with their owner. Use [maintain-skills](../skills/maintain-skills/SKILL.md)
   for skill changes.
3. Update navigation, callers, and provider guides in the same change. Flatten
   routes that add no useful choice. Add a category index only when it reduces
   the amount a reader must inspect. Keep entry points short; move conditional
   detail to a linked reference.
4. Run the checks in the resource guide. Link and manifest validation cannot
   prove semantic consistency: also review ownership, conflicting instructions,
   task triggers, and assumptions about available tools.
5. Install renamed or added resources, check the live targets, and follow the
   [Git workflow](git.md). Existing symlinked content changes immediately;
   restart or begin a fresh provider session when checking discovery.

Do not add generic agent translation or synchronization without a concrete
consumer. Provider roles, models, and permissions have different semantics;
native definitions belong with the provider that executes them.
