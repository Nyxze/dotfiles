# Visual implementation contract (all coding agents)

Scope: visual improvements to the existing Arch/Hyprland + Mint/Xfce/i3 dotfiles. This is a **window-manager-first** setup. Never replace Hyprland/i3 with a full desktop environment. Read the repository root AGENTS.md, .agents/knowledge/machine.md, home/common/.config/theme/DESIGN.md, and home/common/.config/quickshell/endfield/AGENTS.md for Quickshell edits.

## Immutable invariants

- The user owns a live laptop. **Never render, interact, relaunch, capture or move windows on the host desktop.** Execute GUI tests only in a verified VM. The existing preview script must only run in the VM.
- Never directly mutate a managed live config: edit its owning file in home/common or the profile overlay, then apply precise paths using apply-config inside the VM. No --force without explicit authorization.
- No root/system changes on the host. Do not use secrets, real user files or network account data as fixtures. Preserve Xfce fallbacks and the separate Arch/Mint compositor backends.
- Preserve the existing Endfield design vocabulary: semantic palette, 4 px spacing grid, chamfers, restrained accent usage, typography roles, distinct selected/active/focus states. Avoid unsolicited animated backgrounds, visualizers, decorative dashboards.
- AI concept artwork is **not** evidence of implementation. Cite the real VM capture and functional observations.

## Per-component loop

1. Pick exactly one scene and read its plan in plans/. State which existing files own the UI and the hypothesis for the next change.
2. Ensure `doctor <scene>` passes and acquire a baseline capture via `run <scene>`. If capture fails, diagnose infrastructure; **do not change theme CSS to fix VM setup**.
3. Make one coherent, reversible source patch (typically one surface: layout, typography, icon, or colors). Preserve the current git diff; do not reset unrelated work.
4. Deploy exactly those files in the VM using apply-config and reload/restart only the affected guest process.
5. Capture the same scene with the same mode and fixture. Store run.json, capture.png, capture.log; evaluate against an explicitly named same-resolution reference. Observe the rendered PNG directly.
6. Check functional requirements from the scene JSON. Record pass/fail/not-tested with reproducible evidence; screenshots alone cannot prove interactions.
7. Diagnose the **largest remaining deviation** and either iterate, revert the patch, or stop blocked. Complete the report by calling `vh.py record <run-directory> --report <report.json>`; use review.example.json as a schema example. Do not declare success based only on pixel metrics.

## Exit conditions and stopping rules

- Budget: at most eight iterations per component before a human checkpoint. Stop earlier on two consecutive non-improving iterations, a missing display capture, nonrecoverable crash, or a functional regression.
- A visual comparison is diagnostic. A concept reference can be impossible or internally contradictory. Document justified deviations rather than faking pixels.
- Completion requires: real capture from the VM, zero known blocking crashes, functional checklist actually exercised, regressions checked, and a list of remaining visual differences. If any is missing, report **not validated**.
- Implementation and evaluation should be independently reviewed when feasible. The evaluator reads artifacts but cannot modify the implementation during the review.
- Every report must link to the exact run directory and code revision. For each iteration note: hypothesis, files changed, observed differences, functional outcomes and next action.
- Capture generated files under tools/visual-harness/artifacts/ only; keep them out of deployable home/ trees. Commit only source, scenes, plans and test fixtures. Do not commit VM credentials or guest runtime files.

## Delegation-ready task

Implement the Launcher scene first. Run `python3 tools/visual-harness/vh.py scenes`, register the VM compositor session, verify `doctor launcher`, then `run launcher`. Read plans/01-launcher.md and the design system. Iterate with bounded patches and real captures. Return the last capture location, comparison JSON if a reference was provided, functional results, known gaps and exact next action. If the VM is not yet usable, report the environmental blocker, not an invented visual result.
