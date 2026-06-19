---
name: linear-start-issue
description: Fetch a Linear issue and its sub-issues, summarize them, pick the logical starting sub-issue, checkout the corresponding branch from develop, and move the ticket to In Progress.
---

# Linear Start Issue

## Overview

Given a Linear issue URL or ID, fetch the parent issue and all its sub-issues, display a structured summary, recommend the best sub-issue to start with, checkout its branch from `develop`, and move the ticket to **In Progress** in Linear.

## Workflow

### Step 1: Parse the Issue ID

Extract the issue identifier from the input. It may be:
- A full URL: `https://linear.app/<org>/issue/DEV-61/...` → extract `DEV-61`
- A bare ID: `DEV-61`

### Step 2: Fetch Parent Issue and Sub-issues in Parallel

Use both MCP tools simultaneously:
- `mcp__claude_ai_Linear__get_issue` with the extracted ID
- `mcp__claude_ai_Linear__list_issues` with `parentId` set to the same ID

### Step 3: Display a Structured Summary

Present the parent issue with:
- ID, title, status, priority, assignee, description summary
- Acceptance criteria highlights

Then list each sub-issue in a table:

| ID | Title | Status | Estimate |
|----|-------|--------|----------|

Follow with a one-paragraph description of each sub-issue.

### Step 4: Choose the Workflow

**If the issue has no sub-issues**, skip this step and proceed with a single branch (Step 5A).

**If the issue has sub-issues**, ask the user which workflow to use:

> Quel workflow utiliser ?
> - **Stacked PR** — une branche par sous-issue, chacune stackée sur la précédente *(recommandé)*
> - **Single branch** — une seule branche pour toutes les sous-issues

The recommendation is **Stacked PR** whenever there are multiple sub-issues with a clear dependency order.

---

### Step 5A: Single Branch

Sync `develop`, checkout one branch for the issue (use the parent issue's `gitBranchName`):

```bash
git fetch origin
git checkout develop && git pull origin develop
git checkout -b <parent-gitBranchName>
```

Then go to Step 6.

---

### Step 5B: Stacked PR

Determine the dependency order of the sub-issues:
- Foundational / setup tasks first
- Gating / integration tasks after the things they depend on
- Validation and QA tasks last

If the order is ambiguous, confirm with the user before proceeding.

Display the proposed stack before creating anything:

```
develop
  └── <parent-branch>            ← DEV-001
        └── <sub-branch-1>       ← DEV-002
              └── <sub-branch-2> ← DEV-003
```

Then create each branch in order using **git-level stacking**: each branch must be created *from* the previous branch, not from `develop`. This ensures that each branch contains all prior changes and `pyproject.toml`, migrations, config, and other shared files stay consistent throughout the stack.

```bash
# First branch — based on develop
git fetch origin
git checkout develop && git pull origin develop
git checkout -b <sub-branch-1>
git push -u origin <sub-branch-1>

# Each subsequent branch — based on the previous one
git checkout -b <sub-branch-2> <sub-branch-1>
git push -u origin <sub-branch-2>

# ...and so on
```

**Never create stacked branches from `develop` directly.** Doing so creates sibling branches that don't see each other's changes, breaking the stack at the git level even though PRs target each other correctly.

Leave the user on the first sub-issue branch.

---

### Step 6: Move the Ticket to "In Progress"

Move the starting ticket to **In Progress** in Linear.

### Step 7: Offer Codebase Orientation

Ask the user whether they want a quick codebase orientation. If yes, read the issue description and acceptance criteria, locate the relevant files, and give a short map of what to touch and in which order.
