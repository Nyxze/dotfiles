# Claude Code — Official Skills Documentation

Source: https://code.claude.com/docs/fr/skills

## Directory structure & locations

```
Location    | Path                                      | Scope
Personal    | ~/.claude/skills/<skill-name>/SKILL.md    | All your projects
Project     | .claude/skills/<skill-name>/SKILL.md      | This project only
Plugin      | <plugin>/skills/<skill-name>/SKILL.md     | Where plugin is enabled
```

Resolution priority: Enterprise > Personal > Project.

### Internal skill structure

```
my-skill/
├── SKILL.md           # Main instructions (required)
├── references/        # Reference docs loaded on demand
└── scripts/           # Utility scripts Claude can execute
```

---

## Frontmatter reference

```yaml
---
name: my-skill
description: What this skill does and when to use it   # max 1536 chars combined with when_to_use
when_to_use: Additional trigger context
argument-hint: [issue-number]
arguments: [issue, branch]
disable-model-invocation: true   # only user can invoke (use for deploy, commit, irreversible)
user-invocable: false            # only Claude can invoke (background knowledge)
allowed-tools: Read Grep Bash(git add *)
model: claude-3-5-sonnet
effort: high
context: fork                    # run in isolated subagent
agent: Explore                   # Explore | Plan | general-purpose | custom
paths: "**/*.py,**/*.ts"         # glob patterns limiting when skill activates
shell: bash
hooks: ~
---
```

Key fields:
- `description` + `when_to_use` combined max **1536 characters** — this is the primary trigger mechanism
- `disable-model-invocation: true` — for actions requiring explicit user intent (deploy, delete, commit)
- `context: fork` — isolates execution in a subagent; subagent has no conversation history access
- `allowed-tools` — pre-approves tools without per-use permission prompts

---

## Progressive disclosure

Keep `SKILL.md` under **500 lines**. Move detailed material into separate files:

```
my-skill/
├── SKILL.md         # Concise overview + navigation
├── references/
│   ├── api.md       # Detailed API docs
│   └── examples.md  # Usage examples
└── scripts/
    └── helper.py    # Utility code
```

Reference files in SKILL.md:
```markdown
## References
| File | When to read |
|---|---|
| `references/api.md` | Before calling the API — covers auth, rate limits, error codes |
```

Benefits: reference material costs near-zero tokens until needed; Claude loads files on demand.

---

## String substitutions

| Variable | Description |
|---|---|
| `$ARGUMENTS` | All passed arguments |
| `$ARGUMENTS[N]` | Specific argument by index (0-based) |
| `$N` | Shorthand for `$ARGUMENTS[N]` |
| `$name` | Named argument declared in `arguments:` |
| `${CLAUDE_SESSION_ID}` | Current session ID |
| `${CLAUDE_SKILL_DIR}` | Directory containing SKILL.md |

---

## Dynamic context injection

Run shell commands before Claude sees the content — output replaces the placeholder:

```markdown
## Current state
- Diff: !`git diff --staged`
- Status: !`git status --short`
```

Commands run once on the original file; output is not re-parsed.

---

## Skill lifecycle

- When invoked, `SKILL.md` rendered content enters the conversation as a single message
- Stays for the **rest of the session** — Claude Code does not re-read the file on subsequent turns
- Auto-compaction: invoked skills are prioritized in a 25,000-token budget
- First 5,000 tokens of each invoked skill are reattached after compaction

---

## Invocation control

| Config | User can invoke | Claude can invoke |
|---|---|---|
| (default) | Yes | Yes |
| `disable-model-invocation: true` | Yes | No |
| `user-invocable: false` | No | Yes |

---

## Best practices

- State **what to do**, not how or why — Claude is smart enough to figure out the rest
- Every line has a recurring token cost once loaded — apply the same conciseness bar as CLAUDE.md
- Make descriptions **specific** to avoid accidental triggering
- Use `references/` for long material (API docs, examples, specs)
- Use `scripts/` for reusable utility code discovered across multiple test runs
- `context: fork` for research tasks that shouldn't pollute conversation history
