---
name: prose-standard
description: >
  Write, edit, review, or trim reader-facing prose so it keeps every fact,
  reads as plain technical English, and contains no AI filler. Use when
  writing or editing code comments, docstrings, documentation, READMEs, agent
  instructions, diagnostics, reports, or slides, and when a passage reads as
  generated slop. Not for conversational replies or translation.
---

# Prose standard

Write enough to keep every fact the reader relies on, then remove filler,
repetition, and decoration. A shorter passage is better only when every fact
survives and the result is clearer. This skill owns wording and editorial
judgment. [self-contained-prose](../self-contained-prose/SKILL.md) owns
whether a passage stands on its own; apply both to the same scope.

Project instructions win over this skill. Read the applicable `AGENTS.md`,
documentation rules, and the owner of the subject before judging a passage.

## Genre references

Read the reference for the output being written:

- [Code and repository documentation](references/code-and-docs.md): code
  comments, docstrings, tests, READMEs, agent instructions, and diagnostics.
- [Slides](references/slides.md): presentations and presenter notes.

Other genres use the core rules below until a reference exists.

## Keep every fact

Before editing, list the passage's facts. Keep each relevant:

- actor and action;
- condition, timing, and order;
- strength: must, may, should, never;
- exception and negative guarantee;
- ownership, side effect, failure, and consequence;
- number, unit, and degree of uncertainty.

Never strengthen, weaken, or drop one of these to make a sentence shorter.
Never turn a requirement into a suggestion, a hypothesis into a result, or a
measured value into an adjective.

## Plain technical English

- Name the actor and the action. Use active voice when the actor matters.
- Use one term for each concept. Do not rotate synonyms for variety.
- Prefer a direct verb to a noun phrase: "validates" over "performs
  validation of".
- Put one instruction in each sentence. Use a list for three or more steps or
  conditions.
- Split semicolon chains and paragraphs that carry several rules.
- Give the number when one exists instead of "significant", "many", or "fast".

Treat about 20 words for an instruction and 25 for a description as a prompt
to re-read the sentence, not as a limit. Keep a longer sentence when a split
would hide a condition.

## Words to question

Check these before using them; keep one only when it names the exact subject:
contract, boundary, surface, layer, shape, seam, gate, vocabulary, ecosystem,
journey, landscape. Ask whether the exact API, field, check, file, or failure
says it better.

## Remove AI filler

Delete or rewrite on sight:

- Openers and signposts: "It's important to note", "Let's dive in", "In
  today's fast-paced world", "In this section we will".
- Inflated words: robust, seamless, leverage, comprehensive, crucial,
  powerful, cutting-edge, delve, streamline, unlock, empower.
- Reflexive shapes: items padded into groups of three, "It's not X, it's Y",
  rhetorical questions answered in the next sentence, chains of em dashes.
- Recaps: a closing paragraph that restates what the reader just read.
- False balance: "it depends" or "both have merits" where the evidence
  favors one option. State the finding and its condition.
- Stacked hedges: "may potentially", "could possibly help to". Keep one
  hedge when uncertainty is real, and say what it depends on.
- Praise and enthusiasm aimed at the reader or the work.

## Emphasis

Reserve bold or capitals for the one clause that changes behavior or the
comparison that matters. Keep emphasis that carries strength, timing, or
negation; remove decorative emphasis.

## Workflow

1. Confirm the scope. Review requests report findings; write, fix, or trim
   requests apply changes.
2. Read the applicable project instructions, the owning document or code,
   and the genre reference.
3. Classify each passage: keep, add, trim, restore, restructure, or defer.
   Add prose when a fact the reader needs is missing; do not only cut.
4. Fix the owner before any derived copy, such as generated docs or a
   translated counterpart.
5. Run the project's documentation checks when its instructions name them.
6. Report the scope inspected, the changes, deliberate keeps, and deferred
   passages.

## Borderline passages

A passage is borderline when two versions both keep every fact but trade one
rule against another. Report it with two or three such versions and recommend
one; do not offer a weaker distractor. When the user decides, record the rule
and the chosen before/after pair in `references/examples.md` (create it with
the first example) and apply the rule to analogous passages in scope.
