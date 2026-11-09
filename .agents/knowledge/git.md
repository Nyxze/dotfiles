# Git workflow

- Run `git fetch` before inferring repository state from local refs.
- Commit only task-related files. Preserve unrelated working-tree changes.
- Use the [commit skill](../skills/commit/SKILL.md) to create a commit.
- Push completed commits to the configured remote before handing work back.
  If the push fails, report the failure without rewriting history or including
  unrelated changes.
