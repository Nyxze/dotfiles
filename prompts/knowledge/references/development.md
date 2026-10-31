# Development preferences

## Git

- Run `git fetch` before inferring repository state from local refs.

## Managed machine configuration

- The source of personal machine configuration is `~/stuff/dotfiles`. `apply-config` copies its `home/` layers to the home directory. Find and edit the owning source layer, deploy the affected component, and verify the live copy. A live-only change will be overwritten by the next apply.
- If urgent recovery requires a live edit first, port it to the source in the same task. Preserve unrelated source and live edits.
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
