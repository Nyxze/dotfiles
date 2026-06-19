---
name: staged-review
description: Pre-commit code review of staged git changes. Enforces project-specific conventions from AGENTS.md/CLAUDE.md and general best practices. Flags issues with explanations and suggested fixes. Hard-blocks commit on BLOCKING issues.
---

# Staged Review

Pre-commit code review of staged changes only. Reads project conventions, invokes relevant skills, and flags issues before you commit.

## Workflow

### Step 1: Collect Staged Changes

Run in parallel:

```bash
git diff --staged
git diff --staged --name-only
```

If nothing is staged, tell the user and stop.

### Step 2: Categorize Files

For each staged file, infer:

- **Domain**: what feature or concern does this file belong to?
- **Role**: what does this file do? (e.g. entry point, data access, business logic, UI, config, schema, test)
- **File type**: `.tsx`, `.ts`, `.json`, config, etc.

Derive these from the file path, name, and content — do not assume a fixed project structure. Use these categories in Steps 3 and 4 to select which rules apply.

### Step 3: Load Conventions and Invoke Relevant Skills

Always read:
- `AGENTS.md` at the repo root — primary source of project conventions
- `CLAUDE.md` at the repo root — architectural decisions and constraints

Then, based on the file categories from Step 2, scan the available skills list and invoke any skill whose scope matches the staged changes. The goal is to enforce idiomatic and correct usage patterns — not just project rules. Examples of when to invoke skills:

- Mobile components or hooks are staged → look for a React Native / Expo skill
- React component with complex props or composition patterns are staged → look for a React composition skill
- Security-sensitive code (auth, permissions, tokens) is staged → look for a security skill

Use judgment: invoke a skill when the staged diff touches patterns that skill is designed to enforce. Do not invoke skills for files clearly outside their scope.

### Step 4: Review Checklist

Apply checks based on file category.

#### Universal (all files)

- [ ] No `any` type — use `unknown` or proper types
- [ ] No `else` — use early returns
- [ ] `const` over `let` — ternaries or early returns instead of reassignment
- [ ] `async`/`await` over `.then()`/`.catch()` chains
- [ ] Functions under 80 lines — extract cohesive sub-operations if exceeded
- [ ] No comments unless the WHY is non-obvious and not expressible in code
- [ ] Prefer single-word names for locals, params, helpers
- [ ] No unnecessary destructuring — prefer dot notation
- [ ] Functional array methods (`map`, `filter`, `flatMap`) over `for` loops
- [ ] No hardcoded config values — use env vars or a central config module

#### TypeScript

- [ ] `noUncheckedIndexedAccess`: array/object access is `T | undefined` — guard before use
- [ ] `noImplicitOverride`: `override` keyword on overridden methods
- [ ] Type inference preferred; explicit types only for exports or clarity
- [ ] `isolatedModules`: type-only imports must use `import type`

#### Import Order

1. React / framework (`react`, `next/server`, `expo-*`)
2. External third-party libs
3. Shared packages (`@lootopia/api`)
4. Internal app imports (hooks, components, services, theme)
5. Types (`import type`)

#### Backoffice: Route Handlers (`app/api/v1/*/route.ts`)

- [ ] No Prisma calls — must go through a service
- [ ] Input validated with Zod from `@lootopia/api`
- [ ] Success response wrapped in `{ data }`, error in `{ error: { code, message } }`
- [ ] Domain errors caught and mapped to HTTP status — no internal details exposed
- [ ] No HTTP types leaking into services

#### Backoffice: Services (`app/services/*/`)

- [ ] Business logic only — no HTTP types, no Prisma
- [ ] Throws domain errors (`NotFoundError`, `ValidationError`, etc.) from `lib/errors.ts`
- [ ] Imports Zod schemas from `@lootopia/api/v1/schemas`

#### Packages/API: Schemas

- [ ] Exports both the Zod schema and its inferred type (`z.infer<typeof ...>`)
- [ ] Re-exported from barrel files (`v1/index.ts`, `index.ts`)

#### Mobile: UI Components

- [ ] No direct imports from `@lootopia/api` or `services/` — use hooks
- [ ] All user-visible text through i18n — no hardcoded strings in JSX
- [ ] `StyleSheet.create()` at the bottom of the file
- [ ] Named exports (not default)
- [ ] Props interface defined inline above the component
- [ ] PascalCase file name

#### Mobile: Hooks

- [ ] Loading/error state pattern: `setLoading`, `setError`, try/catch/finally

#### Mobile: Services

- [ ] Transforms API types → domain types — never leak `@lootopia/api` types to UI

### Step 5: Report Issues

Group findings into two tiers:

**BLOCKING** — Must fix before committing. Architectural violations, type safety breaks, security issues, or anything that would fail the build or violate a hard project rule.

**SUGGESTION** — Non-blocking: naming, minor style, convention preferences.

For each issue, output:

```
[BLOCKING|SUGGESTION] path/to/file.ts:line
Issue: <what is wrong>
Why:   <why this matters — rule source, risk, or broken invariant>
Fix:   <specific suggested change>
```

If no issues are found, say so clearly and stop.

### Step 6: Offer to Apply Fixes

After the report:

> Found N BLOCKING and M suggestion(s). Apply fixes? (yes / no / select)

- **yes** — apply all BLOCKING fixes
- **no** — stop; user fixes manually or commits as-is
- **select** — list issues numbered; user picks which to apply

Only apply fixes when explicitly asked. Never stage or commit after applying.

## Pre-commit Hook Setup

To run this skill automatically before every commit:

```bash
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/sh
claude --print "/staged-review"
if [ $? -ne 0 ]; then
  echo "staged-review: BLOCKING issues found. Fix them or set SKIP_REVIEW=1 to bypass."
  exit 1
fi
EOF
chmod +x .git/hooks/pre-commit
```

The hook exits non-zero when BLOCKING issues are found, preventing the commit.
Escape hatch: `SKIP_REVIEW=1 git commit` bypasses the hook when needed.

## Key Constraints

- Review staged changes only (`git diff --staged`) — never touch unstaged or committed files
- Never commit, stage, or push anything — read-only unless the user explicitly asks to apply fixes
- Never modify files outside the staged set
- Always read `AGENTS.md` and `CLAUDE.md` before reviewing
- Invoke relevant skills proactively based on what is staged
