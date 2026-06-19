---
name: skill-eval
description: Evaluates an existing Claude Code skill by launching parallel test runs (with and without the skill), grading results, displaying an interactive viewer for human review, and iterating until satisfied. Use this skill whenever the user wants to test, benchmark, evaluate, compare versions of a skill, analyze skill performance, or check if a skill works well on real cases. Also triggers when the user says "run the evals", "test the skill", "run the tests", "does the skill work", or shows an evals.json to evaluate.
---

# Skill Eval

This skill handles the complete evaluation loop for a Claude Code skill:  
**launch runs → grade → show viewer → read feedback → iterate.**

Scripts and agents used here live in the skill-creator:
- Scripts: `/home/nyxze/.claude/skills/skill-creator/scripts/`
- Agents: `/home/nyxze/.claude/skills/skill-creator/agents/`
- Viewer: `/home/nyxze/.claude/skills/skill-creator/eval-viewer/generate_review.py`
- References: `/home/nyxze/.claude/skills/skill-creator/references/schemas.md`

---

## Before you start

Establish these before launching anything:

1. **Which skill to evaluate?** Get the absolute path to the skill folder (e.g. `/home/user/.claude/skills/my-skill/`).
2. **Which test cases?** Look for `evals/evals.json` inside the skill folder. If it doesn't exist, ask the user to provide some or offer to draft 2–3 together.
3. **Which baseline?**
   - **First evaluation** of the skill: baseline = no skill at all (`without_skill`).
   - **Improvement iteration**: baseline = snapshot of the previous version (`old_skill`).
4. **Where to put results?** Create a `<skill-name>-workspace/` directory as a sibling of the skill folder, organized by `iteration-1/`, `iteration-2/`, etc.

---

## evals.json format

```json
{
  "skill_name": "my-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "Prompt the user would actually type",
      "expected_output": "Description of the expected result",
      "files": []
    }
  ]
}
```

See `/home/nyxze/.claude/skills/skill-creator/references/schemas.md` for the full schema including `assertions`.

---

## Main evaluation loop

This is one continuous sequence — don't stop partway through.

### Step 1: Launch ALL runs in the same turn

For each test case, spawn two subagents in the **same turn** (not one after the other):

**With-skill run:**
```
Execute this task:
- Skill path: <path-to-skill>
- Task: <eval prompt>
- Input files: <eval files if any, or "none">
- Save outputs to: <workspace>/iteration-<N>/eval-<ID>/with_skill/outputs/
- Outputs to save: <what matters — generated file, CSV, final text, etc.>
```

**Baseline run:**
- First eval: no skill, same prompt, save to `without_skill/outputs/`
- Next iteration: point to old version snapshot (created with `cp -r <skill-path> <workspace>/skill-snapshot/`), save to `old_skill/outputs/`

Create an `eval_metadata.json` in each test case directory (assertions empty for now):
```json
{
  "eval_id": 0,
  "eval_name": "descriptive-name",
  "prompt": "The test case prompt",
  "assertions": []
}
```

Give each eval a descriptive name — not just "eval-0".

### Step 2: While runs are in progress, draft assertions

Use the wait time productively. Draft quantitative assertions for each test case and explain them to the user. Good assertions are objectively verifiable and have clear names that are immediately understood at a glance in the viewer.

Subjective outputs (writing style, visual quality) don't benefit from assertions — prefer qualitative human evaluation instead.

Update `eval_metadata.json` and `evals/evals.json` with the drafted assertions.

### Step 3: Capture timing as each run completes

When each subagent task completes, you receive a notification containing `total_tokens` and `duration_ms`. Save immediately to `timing.json` in the run directory:

```json
{
  "total_tokens": 84852,
  "duration_ms": 23332,
  "total_duration_seconds": 23.3
}
```

This is the only opportunity to capture this data — process each notification as it arrives.

### Step 4: Grade, aggregate, and launch the viewer

Once all runs are done:

**1. Grade** — Spawn a grader subagent using `agents/grader.md` to evaluate each assertion against the outputs. Save `grading.json` in each run directory. The `grading.json` expectations array must use exactly these fields: `text`, `passed`, `evidence` (not `name`/`met`/`details`). For assertions that can be checked programmatically, write and run a script rather than eyeballing it — faster, more reliable, and reusable.

**2. Aggregate** — Run from the skill-creator directory:
```bash
python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>
```
This produces `benchmark.json` and `benchmark.md` with pass_rate, time, and tokens for each configuration. Put each `with_skill` version before its baseline counterpart.

**3. Analyst pass** — Read the benchmark data and surface patterns the aggregate stats might hide. See `agents/analyzer.md` (section "Analyzing Benchmark Results") for what to look for: non-discriminating assertions (always pass regardless of skill), high-variance evals (possibly flaky), time/token tradeoffs.

**4. Launch the viewer:**
```bash
nohup python <skill-creator-path>/eval-viewer/generate_review.py \
  <workspace>/iteration-N \
  --skill-name "my-skill" \
  --benchmark <workspace>/iteration-N/benchmark.json \
  > /dev/null 2>&1 &
VIEWER_PID=$!
```

For iteration 2+, also pass `--previous-workspace <workspace>/iteration-<N-1>`.

**Headless / Cowork environments:** Use `--static <output_path>` to write a standalone HTML file instead of starting a server. Feedback will be downloaded as `feedback.json` when the user clicks "Submit All Reviews".

⚠️ **IMPORTANT**: Always generate the viewer BEFORE evaluating outputs yourself. Get results in front of the human first.

Tell the user: "I've opened the results in your browser. The 'Outputs' tab lets you click through each test case and leave feedback, 'Benchmark' shows the quantitative comparison. When you're done, come back and let me know."

### Step 5: Read the feedback

When the user says they're done, read `feedback.json`:

```json
{
  "reviews": [
    {"run_id": "eval-0-with_skill", "feedback": "the chart is missing axis labels", "timestamp": "..."},
    {"run_id": "eval-1-with_skill", "feedback": "", "timestamp": "..."}
  ],
  "status": "complete"
}
```

Empty feedback means the user was satisfied. Focus improvements on test cases with specific complaints.

Kill the viewer server:
```bash
kill $VIEWER_PID 2>/dev/null
```

---

## Improving the skill

This is the heart of the loop. You have the results, the user has reviewed — now make the skill better.

### How to think about improvements

**Generalize from feedback.** These few examples help you iterate fast, but the skill will be used thousands of times on varied prompts. Avoid changes that are too specific to the examples. If a problem persists, try different metaphors or patterns rather than forcing rigid rules.

**Keep the prompt lean.** Remove things that aren't pulling their weight. Read the run transcripts — if the skill is making agents waste time on unproductive steps, remove the parts causing that.

**Explain the why.** Prefer explaining the reason behind each instruction over writing ALWAYS/NEVER in caps. Modern LLMs work better with reasoning than rigid rules.

**Spot repeated work across test cases.** If all 3 test cases independently wrote a similar `create_chart.py`, that's a strong signal: bundle that script in `scripts/` once, and point the skill to it.

### Iteration loop

After improving the skill:
1. Apply changes to the skill
2. Rerun all test cases into a new `iteration-<N+1>/` directory, including baseline runs
3. Launch the viewer with `--previous-workspace` pointing at the previous iteration
4. Wait for the user to review and tell you they're done
5. Read new feedback, improve again, repeat

Keep going until:
- The user says they're happy
- All feedback is empty
- Improvements are no longer meaningful

---

## Blind comparison (optional)

For a more rigorous comparison between two skill versions (e.g. "is the new version actually better?"), use the blind comparison system.

Read `agents/comparator.md` and `agents/analyzer.md` for details. The idea: an independent agent compares two outputs without knowing which came from which version, then the analyzer explains why the winner won.

This is optional — the human review loop is usually sufficient. Offer it when the user wants more objective validation.

---

## Description optimization (optional, after finalizing the skill)

The description in SKILL.md frontmatter is the primary triggering mechanism. Once the skill is in good shape, offer to optimize the description for better triggering accuracy.

### Step 1: Generate trigger eval queries

Create 20 queries — a mix of should-trigger and should-not-trigger. Save as JSON:

```json
[
  {"query": "the user prompt", "should_trigger": true},
  {"query": "another prompt", "should_trigger": false}
]
```

Queries must be realistic and concrete (with context, file paths, column names, backstory). Avoid obvious cases — focus on edge cases.

**For should-trigger (8–10)**: varied phrasings, formal and casual. Include cases where the user doesn't name the skill explicitly but clearly needs it.

**For should-not-trigger (8–10)**: the most valuable are near-misses — queries that share keywords but actually need something different. "Obviously unrelated" queries don't test anything.

### Step 2: Review with user

1. Read the template: `/home/nyxze/.claude/skills/skill-creator/assets/eval_review.html`
2. Replace `__EVAL_DATA_PLACEHOLDER__` with the JSON array, `__SKILL_NAME_PLACEHOLDER__` and `__SKILL_DESCRIPTION_PLACEHOLDER__` with their values
3. Write to `/tmp/eval_review_<skill-name>.html` and open it
4. User edits, then clicks "Export Eval Set" → downloads `eval_set.json`

### Step 3: Run the optimization loop

Tell the user: "This will take some time — I'll run the optimization loop in the background."

```bash
python -m scripts.run_loop \
  --eval-set <path-to-trigger-eval.json> \
  --skill-path <path-to-skill> \
  --model <model-id-powering-this-session> \
  --max-iterations 5 \
  --verbose
```

Use the model ID from your system prompt so the triggering test matches what the user actually experiences.

Periodically tail the output to give the user updates on iteration scores.

### Step 4: Apply the result

Take `best_description` from the JSON output and update the skill's SKILL.md frontmatter. Show before/after and report the scores.

---

## What the user sees in the viewer

The **Outputs** tab shows one test case at a time:
- **Prompt**: the task that was given
- **Output**: files produced, rendered inline where possible
- **Previous Output** (iteration 2+): collapsed section with last iteration's output
- **Formal Grades**: collapsed section with assertion pass/fail results
- **Feedback**: textbox that auto-saves as they type
- **Previous Feedback** (iteration 2+): their comments from last time

The **Benchmark** tab shows the stats summary: pass rates, timing, and token usage per configuration, with per-eval breakdowns and analyst observations.

Navigation via prev/next buttons or arrow keys. "Submit All Reviews" saves all feedback to `feedback.json`.
