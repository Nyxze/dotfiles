# Development conventions

## Ownership

- Give each fact, rule, behavior, and piece of shared state one authoritative
  owner. Find and update that owner before adding another definition or mechanism.
- Other consumers link to, call, or derive from that source. Use symlinks or
  generated copies when the same content needs several entry points; do not
  maintain independent copies by hand.
- Keep each owner's scope clear. Split genuinely different responsibilities;
  do not create a second home merely for another tool, provider, or document.

## Code style

- Keep code simple. Prefer guard clauses and early returns over deeply nested
  conditionals.

## Prose

- Comments state only non-obvious reasons or invariants, and all reader-facing
  content stands on its own.
- For code comments, docstrings, documentation, reports, and slides, apply
  [prose-standard](../skills/prose-standard/SKILL.md) and
  [self-contained-prose](../skills/self-contained-prose/SKILL.md); they own
  the detailed rules.

## Architecture

- Challenge organizational or architectural work with no concrete consumer or
  current problem, even when the user suggests it. State the practical cost and
  recommend a hard stop before adding layers, abstractions, folders, or
  documentation structure for possible future use. Resume when a real need and
  acceptance check justify the work. Apply this in Codex, Claude Code, and OpenCode.
- Keep module boundaries clear, with one concern per module and dependencies
  pointing one way.
- Whenever introducing or changing an abstraction or an API between modules,
  provide a small usage example before or alongside the implementation so
  the user can assess its ergonomics. Use a self-contained code snippet or
  a standalone program with a direct run command; make it easy to modify.
  Do not require a test runner to explore the API, and do not wait for a
  separate request. Tests verify behavior but do not replace usage examples.
  The example need not be permanent unless requested.
- Keep interfaces small. Split by concern instead of extending an interface
  that grows too broad.
- Treat files above roughly 500 lines as a sign to split responsibilities.
- Prefer an elegant, simple solution over a clever or exhaustive one. Ask when
  an architectural or naming choice is genuinely unclear.
