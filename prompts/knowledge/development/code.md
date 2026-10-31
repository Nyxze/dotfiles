# Code style

- Keep code simple. Prefer guard clauses and early returns over deeply nested
  conditionals.
- Keep comments sparse. Explain non-obvious reasons or invariants, not what
  code already says. Trivial helpers need no doc comment; exported APIs get
  terse documentation. Examples may retain teaching comments.
- Code comments and docstrings must be self-contained. Do not point to external
  documents, sections, ADRs, or ticket IDs. Before finalizing, scan source
  comments for ticket-shaped tokens such as `[A-Z]+-[0-9]+` and for “see X”
  pointers. Ticket IDs may belong in commits, PRs, and Linear comments, but not
  in source comments.
