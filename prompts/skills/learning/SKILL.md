---
name: learning
description: Reflects on the current session to synthesize non-obvious lessons and pass them down to the relevant AGENTS.md files.
---

## What I do
I engage in a process of **reflection** on our current interaction. My goal is to identify "hard-won lessons"—those moments where the code behaved unexpectedly, where a mental model was proven wrong, or where a subtle architectural constraint was discovered. I then "teach" these lessons to future agents by placing them in the appropriate hierarchical `AGENTS.md` file.

## What constitutes a "Lesson"
A lesson is a piece of **acquired wisdom**. I look for:
- **"The Gotchas":** Realizations that came after multiple failed attempts (e.g., "I thought X worked like Y, but it actually requires Z").
- **Mental Model Shifts:** Insights that change how one views the module's behavior.
- **Hidden Dependencies:** Discovering that "File A" only works if "File B" is configured in a specific, non-obvious way.
- **Quirk Wisdom:** Documenting the *why* behind a weird workaround so it isn't "fixed" later by someone who doesn't know the history.
- **Optimization Secrets:** Hard-coded limits or flags found through trial and error.

## What I ignore
- Rote facts found in the documentation.
- Standard "best practices" that apply to every project.
- Redundant info already captured in an `AGENTS.md`.
- Transient debugging logs or session-specific noise.

## The Hierarchy of Wisdom
I place the lesson where it is most relevant to ensure "Contextual Inheritance":
1. **Universal Lessons:** Root `AGENTS.md`.
2. **Domain/Module Lessons:** `packages/audio/AGENTS.md`.
3. **Specific Feature Lessons:** `src/auth/AGENTS.md`.



## My Learning Process
1. **Reflect:** I look back at the "friction points" of the session. Where did we struggle? What was the breakthrough?
2. **Categorize:** I decide the scope—is this a lesson for the whole project or just this sub-folder?
3. **Synthesis:** I read existing `AGENTS.md` files to ensure I'm building upon existing knowledge rather than repeating it.
4. **Present Lessons:** I provide a summary of the synthesized lessons.
   - **MANDATORY:** I do not write these down until you approve them.
   - **Display:** I show the path of the `AGENTS.md` and the 1-3 line "Lesson Learned."
5. **Confirmation:** I ask: "Do these lessons accurately reflect what we learned today? Should I record them?"

## Format
Keep it human and punchy. 1-3 lines per lesson.
