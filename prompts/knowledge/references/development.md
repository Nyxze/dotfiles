# Development preferences

## Git

- Run `git fetch` before inferring repository state from local refs.
- Push completed commits to the configured remote before handing work back. This is a standing user preference across tools; do not wait for a separate push request. If the remote rejects the push or authentication is unavailable, report the failure without rewriting history or including unrelated changes.

## Managed machine configuration

- The source of personal machine configuration is `~/stuff/dotfiles`. `apply-config` copies its `home/` layers to the home directory. The repository must contain every intended change so another machine can reproduce it.
- For every OS or desktop configuration change, use this sequence:
  1. Identify the active profile, owning source layer (`home/common/` or the profile overlay), and exact live paths. Compare their contents with the last synchronized checksums before editing. Treat unexpected live changes as user preferences to reconcile, not as disposable output.
  2. Edit the owning repository files. If urgent recovery requires a live edit first, copy that change into the owning source in the same task before any broader deployment.
  3. Deploy only the affected paths with `./apply-config --profile PROFILE .config/path/to/file` (or a component only when every file in it is intentionally in scope). Never use `--force` to discard a user's version without their explicit choice.
  4. Verify that source and live files match, then verify the running service and the changed behavior. Run visual checks on a separate display. If a component must restart, use its persistent service or a detached launch and confirm it remains running after the command session ends.
  5. Commit and push the source change. Keep unrelated worktree edits out of the commit. A live-only fix or an unpushed source change is unfinished.
- Use `capture-config --profile PROFILE .config/path/to/file` only for a deliberate live change when the repository side still matches the last synchronized copy. If both sides changed, reconcile them manually in the repository first.
- Global agent instructions are the exception to the copied home layers: edit `prompts/knowledge/AGENTS.md` or its references. Provider entrypoints link to that source through `prompts/link-knowledge.sh`.

## Code style

- Keep code simple. Prefer guard clauses and early returns over deeply nested conditionals.
- Keep comments sparse. Explain non-obvious reasons or invariants, not what code already says. Trivial helpers need no doc comment; exported APIs get terse documentation. Examples may retain teaching comments.
- Code comments and docstrings must be self-contained. Do not point to external documents, sections, ADRs, or ticket IDs. Before finalizing, scan source comments for ticket-shaped tokens such as `[A-Z]+-[0-9]+` and for “see X” pointers. Ticket IDs may belong in commits, PRs, and Linear comments, but not in source comments.

## Architecture

- Keep module boundaries clear, with one concern per module and dependencies pointing one way.
- When a module exposes a new public API, offer a runnable example or demo before or right after implementation so the user can try its shape. Ask whether they want one; passing tests alone does not establish that the API feels right. The demo need not be permanent unless requested.
- Keep interfaces small. Split by concern instead of extending an interface that grows too broad.
- Treat files above roughly 500 lines as a sign to split responsibilities.
- Prefer an elegant, simple solution over a clever or exhaustive one. Ask when an architectural or naming choice is genuinely unclear.
