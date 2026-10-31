---
name: commit
description: Create a selective conventional commit with the user's commiter script, preserving unrelated changes and append-only history.
---

# Commit

1. Inspect `git status`, the current branch, and the task diff. Select explicit
   task-related paths; never stage the whole repository or pass `.`.
2. Use a short imperative Conventional Commits subject, with a scope when
   useful: `type(scope): description`. Keep it under roughly 72 characters.
3. Run `commiter "type(scope): description" path...`. It stages the listed paths
   and creates the commit. Never amend or call `git commit` directly.
4. Verify the new commit and push it to the configured remote, following the
   [shared Git workflow](../../knowledge/development/git.md).

If a path's ownership is unclear, leave it out and ask. If `commiter` fails,
report its error before deciding whether a retry is safe.
