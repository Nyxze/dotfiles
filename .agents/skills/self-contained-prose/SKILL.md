---
name: self-contained-prose
description: >
  Find and fix prose that only its authoring session can understand: citations
  of conversations, plans, tickets in source comments, private workspaces, or
  commits; "this PR" or "this increment" vantage; change narration such as
  "used to" or "no longer"; review arguments; and planning residue. Use when
  writing or reviewing code comments, documentation, reports, or slides that
  others will read without the session's context.
---

# Self-contained prose

Reader-facing content must stand on its own. A reader holds only the
delivered artifact: the repository at HEAD, the report, or the deck. This
skill finds prose written from the authoring session's vantage and restates
its facts from the reader's vantage. [prose-standard](../prose-standard/SKILL.md)
owns wording; apply both to the same scope. Project instructions win where
they define their own citation rules.

## The test

For each suspect passage ask: could the reader, without any conversation,
plan, ticket thread, PR discussion, private workspace, or unsent draft,
resolve every reference and verify every claim? If yes, keep it. If no,
restate each surviving fact directly and delete the rest. A passage with no
surviving fact is deleted.

## Leakage classes

1. **Session citations:** decision or plan numbers, phase labels, "as
   discussed", "per our call", links to conversations or private workspaces
   such as Notion pages or chat shares, and references to tools, skills, or
   configuration that only the author has installed. In documents, cite a committed owner
   by relative link or restate the fact; in code comments, restate it.
2. **Change vantage:** "this PR adds", "this increment", "the previous
   version", "in this change". State the shipped mechanism.
3. **Change narration:** "used to", "no longer", "was renamed", "the old X",
   "now" contrasting with a past state. State the present behavior. A fixed
   regression becomes a present-tense counterfactual: "without X, Y happens".
4. **Review choreography:** "rejected in review", "as requested", draft
   numbers. Keep the decision as plain fact.
5. **Reviewer-addressed justification:** "this is safe because". State the
   invariant, or delete the sentence when the code shows it.
6. **Derivation transcripts:** narrated control flow, test walkthroughs,
   proofs of obvious branches. Keep only a non-obvious invariant.
7. **Planning residue:** "probably fine for now", "should be enough",
   deferrals without an owner. State the actual bound, or move the deferral
   to the project's tracker or roadmap.
8. **How the idea arrived:** who suggested it, unrelated projects, the
   methods tried before the final one. State methods and prerequisites
   directly.

## Code comments and docstrings

They must not point to external documents, sections, ADRs, or ticket IDs, and
must not say "see X". Ticket IDs belong in commits, PRs, and tracker
comments. Scan source comments for ticket-shaped tokens such as
`[A-Z]+-[0-9]+` and for "see" pointers before finishing.

## Keep

- External references that support verification, required attribution, or
  an actual tool or dependency, such as a protocol specification or a
  standard's section number.
- Runtime state changes: "the connection can no longer send" describes a
  live object, not history.
- History, status, and dates in documents that own them: a roadmap,
  changelog, decision record, or postmortem.
- Measured values with their evidence.
- Phrases quoted as code, such as examples in this skill.

## Workflow

1. Read the project instructions and run the project's documentation checks
   when they name any.
2. Run the advisory probes over the scope, adding `--glob` filters for its
   file types. Every hit needs judgment; zero hits proves nothing, so also
   read the densest changed prose without a pattern.

   ```sh
   rg -n -i '\bthis (pr|commit|increment|branch|change)\b|\bas discussed\b|\bper our\b'
   rg -n -i '\bused to\b|\bno longer\b|\bpreviously\b|\bthe old\b|\bwas (renamed|moved|removed)\b'
   rg -n -i '\bfor now\b|\bprobably\b|\bshould (be enough|suffice)\b|\bin review\b|\breviewer\b'
   rg -n '\b[A-Z][A-Z0-9]+-[0-9]+\b|\bsee [A-Z]|notion\.(so|site)|claude\.ai|chatgpt\.com/share'
   ```

3. Before deleting, list the passage's facts; keep obligations, bounds, and
   failure behavior.
4. Fix the fact at its owner, not in a derived copy.
5. Report each change with its location, plus deliberate keeps.
