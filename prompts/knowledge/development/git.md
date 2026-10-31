# Git workflow

- Run `git fetch` before inferring repository state from local refs.
- Commit only task-related files. Preserve unrelated working-tree changes.
- Push completed commits to the configured remote before handing work back.
  If the push fails, report the failure without rewriting history or including
  unrelated changes.
