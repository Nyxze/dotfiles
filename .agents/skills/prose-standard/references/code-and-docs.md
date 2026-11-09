# Code and repository documentation

Prose in code and repositories states what code, types, and structure cannot
show. Add prose when a required fact below is missing; delete prose that only
restates the code.

## By location

- **Code comments:** keep them sparse. State a non-obvious reason, invariant,
  ordering constraint, ownership rule, security boundary, or surprising
  failure. Delete control-flow narration ("first we X, then we Y") and code
  restatement.
- **Docstrings of exported APIs:** keep them terse. State what a caller
  cannot see from the signature: return distinctions, errors, side effects,
  ownership, timing, cancellation, and durability. Trivial helpers need none.
- **Module or package comments:** state the role, dependencies, and any
  non-obvious design choice.
- **Tests:** explain only non-obvious design: why a fixture, assertion,
  platform accommodation, real entry path, or indirect observation is needed.
  Delete walkthroughs and inventories of cases.
- **Examples:** may keep teaching comments.
- **READMEs and reference pages:** state what the reader can do with the
  subject, then configuration, behavior, failures, limitations, and extension
  points. Explain the design; do not enumerate every API or restate
  generated catalogs. Describe current state; status and history belong to
  the project's roadmap, changelog, or commits.
- **Tutorials and how-to pages:** prerequisites, the real entry path, steps,
  and how the reader recognizes success or recovers from a likely failure.
- **Agent instructions and skills:** state guardrails, scope limits, and when
  not to act. Keep the workflow short and link the owner of each rule.
- **Diagnostics and error messages:** name the failing subject or path, the
  rule it broke, and the correction when it is not obvious. Remove internal
  execution narration.
- **User-visible strings and model prompts:** wording is behavior. Change them
  only with the project's behavior evidence, such as a snapshot or test.

## Repetition

One explanation has one home; link to it elsewhere. A fact a caller needs at
the point of use may repeat locally. Keep rationale once, at the owning
function or module, not beside each sibling.

## Size

A document that grows too large costs every reader who needs one fact from
it. When it exceeds a project's word budget, or a lookup means scanning
unrelated sections, act in this order:

1. Relocate content that another owner should hold, and leave a one-line
   link.
2. Condense what belongs here, keeping every fact.
3. Split a distinct subject into its own document when the reader need is
   distinct.
4. Raise the budget only when the words are needed, and state why in the
   commit.

Judge size by the reader's path: words read before the needed fact, the
largest section, and unrelated material on the way. Exhaustive references
may stay long when their subject requires it.
