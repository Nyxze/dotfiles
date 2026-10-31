# Handoff: reorganize shared agent knowledge

## Objective

Rework the dotfiles repository's shared agent documentation into a navigable,
topic-based knowledge base for both people and AI agents. A small global entry
point should direct readers to concise indexes. Each index should contain a
relative link and a short description of when to open the resource; detailed
content should load only when relevant. The structure should move from broad
topics to narrower ones without duplicating instructions across levels.

This work is intended for a separate session. The deliverable is an implemented
repository reorganization, not just a proposed tree.

## Current entry points

- `prompts/knowledge/AGENTS.md` is the shared global instruction file. Codex,
  Claude Code, OpenCode, and the home entry point link to it.
- `prompts/knowledge/references/` contains development, interactive operation,
  and managed configuration procedures.
- `prompts/MAIN.md` currently describes installation, provider links, skills,
  agents, and capture. Its role as an installation index is mixed with the
  desired knowledge navigation role.
- `prompts/providers/` contains provider installation guides; `prompts/adapters/`
  contains conversion code.
- `prompts/agents/` contains three agent definitions:
  `frontend-developer.md`, `mobile-developer.md`, and `ui-designer.md`.
- `prompts/skills/` contains reusable skills, including `android-record`,
  `create-pr`, and `create-cli`.

## Required design

1. Define distinct roles for the global `AGENTS.md`, the top-level knowledge
   index, topical indexes, detailed references, skills, agent definitions, and
   provider installation documentation. Keep installation mechanics separate
   from topic navigation.
2. Make the global entry point short and stable. Its links must let an agent
   discover the right topic from any project without loading all reference
   content. Each index entry needs a useful, concise description of its scope
   and trigger.
3. Organize subjects as a shallow funnel: broad topic, narrower topic, then
   detailed procedure. Use additional levels only where they improve discovery.
   Avoid duplicate rules and circular navigation.
4. Use relative repository links and portable path discovery. Avoid embedding a
   particular user's home directory or checkout location in documentation or
   scripts. Keep examples executable from a clearly defined working directory.
5. Preserve the repository-first managed configuration rule, the shared source
   used by all three providers, and the existing provider-specific installation
   behavior. Do not overwrite or absorb unrelated working-tree changes.
6. Audit links, names, and script locations against the chosen conventions.
   Update references and installation scripts together when moving files.

## Content decisions

- Remove the three definitions currently in `prompts/agents/` as part of the
  cleanup, after checking whether installation or conversion expects them.
- Remove `prompts/skills/android-record` and its installed links as part of the
  skill cleanup. Check whether another maintained Android workflow replaces it.
- Review `prompts/skills/create-pr`; its retention is undecided.
- Defer the detailed decision about `prompts/skills/create-cli` until later.
- Audit the remaining skills by actual use and ownership. Keep provider-owned
  skills separate from personal shared skills.

## Acceptance criteria

- A new agent starting in an unrelated project can find the right knowledge
  resource from the global entry point by reading only links and descriptions.
- `AGENTS.md`, `MAIN.md`, topic indexes, detailed references, skills, agents,
  adapters, and provider guides each have a clear, non-overlapping role.
- All internal Markdown links resolve, and no new machine-specific absolute
  paths are introduced.
- Installation and link behavior works for Codex, Claude Code, and OpenCode
  after the migration; removed resources have no stale installed links.
- Relevant tests or validation scripts pass. The final diff excludes unrelated
  existing edits, and the completed change is committed and pushed.

## First actions in the next session

Read the repository `AGENTS.md`, the shared global instructions, `prompts/MAIN.md`,
and the current `prompts/` tree. Inspect the install and capture scripts before
moving files. Draft a small target tree and a link migration map, then implement
and validate it. Ask for a decision only where the content decisions above are
explicitly open.
