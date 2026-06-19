---
name: commit
description: Create a git commit following the user's workflow: branch-scoped conventional commits, selective file staging, short self-describing messages, append-only history.
---

# Commit

## Overview

Guide the user through creating a clean, conventional commit scoped to the current branch task. No amending, no mass staging, no verbose messages.

## Workflow

### Step 1: Inspect Current State

Run these in parallel:

```bash
git status
git branch --show-current
git diff
```

Use `git status` to identify changed files. Use the branch name to derive the default scope. Use `git diff` to understand what actually changed.

### Step 2: Derive the Scope

Parse the branch name to extract the scope:
- Branch `feat/auth` → scope `auth`
- Branch `fix/user-login` → scope `user-login`
- Branch `chore/cleanup` → scope `cleanup`

If the commit type doesn't match the branch prefix (e.g., a quick `chore` or `fix` on a `feat/` branch), use the appropriate type but keep the same scope — unless the change is clearly unrelated, in which case skip the scope.

### Step 3: Select Files to Stage

Do NOT pass "." to the commiter script — it is explicitly rejected.

Look at `git status` output and identify which files are relevant to the current task (matching the branch scope/intent).

- If it's obvious which files belong to this commit, proceed.
- If there are unrelated or ambiguous files (e.g., unrelated config changes, files from another concern), **ask the user** which ones to include before committing.

### Step 4: Compose the Commit Message

Follow the Conventional Commits format:

```
<type>(<scope>): <short description>
```

Rules:
- **type**: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `perf`, `style`, `ci`
- **scope**: derived from the branch name (see Step 2), omit only if truly not applicable
- **description**: short, imperative, self-describing — no period at the end
- **No body**: keep the message to one line. If the change is non-obvious, at most one short sentence body — but default to no body.
- Max ~72 characters on the subject line

Good examples:
```
feat(auth): add JWT refresh token support
fix(user-login): handle empty password edge case
chore(deps): bump go modules
refactor(api): extract pagination helper
```

Bad examples:
```
update stuff                        ← not conventional
feat(auth): Added JWT token support ← past tense, period
feat: lots of changes               ← vague
```

### Step 5: Confirm and Commit

Show the user:
- Files to be committed
- The proposed commit message

Ask for confirmation. If the user wants changes, adjust before committing.

Once confirmed, use the `commiter` script — it handles staging internally:

```bash
commiter "<type>(<scope>): <description>" <file1> <file2> ...
```

The script:
- Resets the staging area, then stages exactly the listed files
- Rejects "." as a path — always list specific files
- Rejects an empty or whitespace-only message
- Supports `--force` as the first flag to remove a stale `.git/index.lock` if needed

Never use `git commit` directly. Never use `--amend`.

### Step 6: Handle Failures

If `commiter` exits non-zero:
1. Show the user the exact error output.
2. Diagnose the cause:
   - `"."` passed → list specific files instead
   - Stale lock file → suggest rerunning with `commiter --force ...`
   - No staged changes → the listed files may have no diff; verify with `git diff <files>`
   - Any other error → show the stderr and suggest a targeted fix or change to the script
3. Do not retry silently — always report to the user before any follow-up action.

### Step 7: Done

Confirm the commit was created with `git log --oneline -1`. No push unless the user explicitly asks.

## Key Constraints

- **Always** use `commiter` script — never `git commit` directly
- **Never** pass `"."` to `commiter` — list specific file paths
- **Never** amend — append only
- **Never** write long commit messages or bodies unless the user asks
- **Always** ask before committing ambiguous/unrelated files
- **Always** derive scope from the branch name by default
- **Always** report `commiter` failures to the user before retrying
- **No pre-commit checks** — trust the user to have validated their changes
