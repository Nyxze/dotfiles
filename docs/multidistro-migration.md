# Multi-distribution migration plan

Status: **planning only**. No implementation is included in this document.
Target: preserve the existing Arch Linux + Hyprland setup while adding an
employer-provided Linux Mint machine with a shared, maintainable configuration.
Cinnamon is assumed for planning only; the Mint release, desktop session and
permission to install packages or change system settings remain unconfirmed.

Read [the target architecture](multidistro-architecture.md) for directory
ownership, profile semantics, provisioning boundaries and invariants. This
document describes *how to reach it*. Each phase should land as a separately
reviewable PR, with Arch remaining usable at every boundary.

## Current baseline

The current repository mirrors a single Arch/Hyprland machine:

- `.config/` and `.local/` mix terminal apps, visual theme, session services,
  desktop integrations and compositor-specific scripts.
- `deploy` and `sync-files` mirror tracked application directories,
  `~/.local/scripts`, the Endfield icon theme and selected desktop entries.
  They already implement a modification-time/checksum guard, `--force`,
  exclusions for working documents, and scoped file lists for VS Code and
  OpenCode. These behaviors must be preserved.
- `scripts/rice` performs Arch package operations with Pacman/Yay and
  session-specific changes (including masking SwayNC and selecting GTK
  settings). It is neither a portable package inventory nor an independent
  bootstrap.
- Root-owned SDDM files are deployed through `scripts/install-system.sh`;
  it stages theme material generated from Quickshell and the shared palette.
- `install.sh` discovers and runs top-level `scripts/*.sh` by filename,
  so it must not become the multi-platform installer unchanged.
  `dev-env.sh` copies broad source directories and calls `hyprctl reload`;
  it must not be used on Mint as a general deployment path.
- `.zshrc` and `.zsh_profile` include absolute home paths and
  platform-specific NVM initialization. `.local/scripts/preview` imports
  Hyprland Lua IPC. These are concrete examples of hidden coupling.
- Ghostty uses `NotoMono Nerd Font` and the Endfield palette. The terminal
  milestone must install that font when possible, or adapt the palette and font
  intent to the terminal already available on the work machine.
- Rofi is an optional application launcher rather than a Hyprland-only
  component. Its configuration/theme can be shared, while its Hyprland bind,
  Quickshell shortcut hand-off and other compositor integration cannot. Its
  current theme also hard-codes an artwork path under `/home/nyxze`.
- Hyprland's Lua configuration, scripts, Quickshell QML and some status-bar
  commands depend on the current Hyprland IPC; moving them does not make
  them portable.
- The tracked `autostart` entries hide `nm-applet` and
  `blueman-applet` because Quickshell replaces their interfaces. Applying
  those entries to Cinnamon would remove expected desktop functionality.
- Only `tests/test_hypr_lua_ipc.py` is currently present in the tracked
  test directory. Deployment/profile regression tests must be added.

The existing `HYPRLAND-MIGRATION.md` describes the separate Hyprland Lua
parser migration; that work is not reopened by this restructuring.

## Phase 0 — Documentation and decisions (this PR)

Deliver:

- The architectural contract in `docs/multidistro-architecture.md`.
- This migration plan, including the source inventory, phased changes,
  failure modes and acceptance criteria.

Decisions to settle at the beginning of implementation, using evidence from
the target hosts rather than assumptions:

1. Confirm the Mint release, desktop session (Cinnamon is only assumed),
   installed packages, default display manager and restrictions on the work
   machine, including whether package installation is permitted.
2. Choose a small manifest format and the local active-profile state location.
3. Decide which Endfield GUI components are explicitly enabled on Mint after
   the terminal tools are usable; keep the stock desktop behavior where no
   port has been tested.
4. Document the packages unavailable through Mint's official repositories
   and choose an acceptable source or mark the feature optional.
5. Decide which machine-specific values need an ignored local override
   (display layout, home-dependent paths, device names).

Acceptance: the two intended profiles, privilege boundaries and ownership
rules are understood; no system or application files have been modified.

## Phase 1 — Portable terminal tooling (first usable milestone)

Deliver a `work-mint-tools` profile that selects the Mint platform and no
desktop. This is the first usable result, not a dependency on completing the
entire desktop migration or on designing a general installer framework. It
must use the same explicit resolved manifest for deploy and capture, with the
existing ownership and conflict safeguards, but may initially cover only the
components below.

Scope:

- Zsh initialization without the current absolute-home assumptions.
- Tmux and the existing session workflow, including opening a session rooted
  in a project directory chosen by the user.
- Yazi and portable terminal scripts.
- A terminal font and Endfield colours: Ghostty when it is available and
  permitted, otherwise a small terminal adapter for the installed terminal
  that preserves the `NotoMono Nerd Font`/palette intent as far as it supports.
- Optional Rofi configuration/theme when Rofi is available. Make its artwork
  path portable; do not include the Hyprland binding or Quickshell hand-off.

The profile must not deploy desktop settings, activate a session, import
Cinnamon preferences, install a display manager or require workspace/window
automation. Provisioning is conditional on the permissions and package sources
available on the work machine; a missing package must be a clear prerequisite
failure, not a reason to run privileged commands implicitly.

Acceptance:

- `work-mint-tools` has an explicit Mint platform selection and no desktop
  selection.
- Deploy and capture use one manifest and retain guarded conflict behavior for
  every path in the milestone.
- Zsh, Tmux, Yazi, the configured terminal font and the Endfield terminal
  palette work on the actual machine or report the exact unavailable
  prerequisite.
- A Tmux session can be opened in a user-chosen project directory.
- No desktop configuration, session activation or Arch/Hyprland path is read
  or modified.

## Phase 2 — Inventory and dependency classification

Deliver a checked inventory for every tracked application/directory/file,
plus the executable scripts and packages each component actually requires.

For each component record:

- Source path, installed path, owner (`common`, desktop, platform, optional
  feature or host), source-of-truth status and deployment mode (directory
  mirror, scoped files, single file, generated or privileged).
- Direct executable, library, font, session and service dependencies;
  installed package source per platform when known.
- References to other repository paths or commands, and whether it is
  safe to deploy and capture independently.
- Whether an application modifies its own settings and needs capture,
  or whether its files are generated and must never be captured back.

Inspect all of `.local/scripts/` individually. Classify screenshot,
clipboard, display, launcher, shortcut and session scripts by the *commands
they invoke*, not by their filename or directory. Inspect settings that
disable an existing service or override Cinnamon-managed preferences.

Record a reproducible Arch baseline before moving files: effective
Hyprland config and binds, displays/workspaces, status bar/Quickshell,
notifications, network/Bluetooth behavior, shell init, launchers,
screenshots, font/theme behavior and a sample of current deploy/sync
conflicts. Make an out-of-repository backup of live managed directories.

Acceptance: every tracked deployable path has an owner and a destination;
all obvious Arch-only and Hyprland-only dependencies are labeled;
the baseline and rollback path are documented.

## Phase 3 — Relayout with zero intended behavioral changes on Arch

Move files into `common/`, `desktop/hyprland/` and the relevant shared
asset locations. Split `.local/scripts/` only after the inventory. Preserve
real target paths under `$HOME`; moving the repository must not require
renaming application configuration directories.

Adapt `deploy` and `sync-files` **together** to consume the same explicit
list of managed sources/destinations. Preserve the already-usable
`work-mint-tools` subset while resolving `personal-arch` to its current
deployment set. Retain:

- Existing conflict guards, scoped VS Code/OpenCode handling,
  documentation exclusions and `--force` semantics.
- User-owned `~/.local/scripts`, Endfield icons and selected desktop
  entries, with explicit ownership rather than broad discovery.
- Existing prompt-provider deploy/capture/adaptation semantics.
- Generated SDDM assets and shaders as derived outputs, not independent
  configuration owners.

Handle moves and removals as migrations, not a blanket `rsync --delete`
across the old and new trees. Check for collisions (e.g. a common
`settings.ini` and a desktop-specific `settings.ini` targeting the
same GTK path). Require explicit file-level ownership or selection;
otherwise fail before changing anything.

Update relative links and code that currently assumes the root `.config`
layout: Hyprland tests, `scripts/build-shaders.sh`,
`scripts/install-system.sh`, design-system references, root and Quickshell
`AGENTS.md`, reload instructions and any live-copy verification commands.
Check whether older `install.sh`/`dev-env.sh` workflows should be adapted
or retired; do not leave an unsafe second installation path.

Recommended implementation order: add resolved-manifest tests and a
non-mutating plan first, introduce the new paths, then cut over
`personal-arch` with an explicit rollback copy. A repository rename alone
is not a sufficient validation.

Acceptance:

- `personal-arch` resolves to the same installed files and behavior as
  before, aside from documented intentional cleanups.
- Dry-run shows no Mint/Cinnamon configuration and no unexpected deletions.
- Deploy -> capture -> deploy round trips preserve content and conflict
  detection, including scoped apps.
- Generated SDDM files still stage correctly; root deployment is explicit.
- Arch's live Hyprland session passes the recorded baseline checks.

## Phase 4 — Profile-aware bootstrap and package adapters

Expand the minimal tools-profile selection into a complete profile interface
without changing the working Arch defaults. Introduce a proposed
`./bootstrap --profile <name>` interface; final names and manifest syntax
should be chosen during implementation.

Separate three operations, each individually invocable/testable:

1. **Resolve/plan**: validate the requested profile against
   `/etc/os-release`, build the component/package/file ownership plan,
   check conflicting destinations and display changes without mutating.
2. **Provision**: install required packages through the selected platform
   adapter and perform narrowly scoped, explicitly opted-in system actions.
3. **Deploy**: copy the resolved user configurations with the existing
   safety checks, then perform selected application-specific activation.

A profile may be saved locally after successful bootstrap; it must not be
committed to the shared repository or inferred silently on subsequent runs.
Keep `deploy` and `sync-files` usable independently of package installation.
Document whether a command needs root *before* executing it. Require explicit
opt-in for SDDM, masking user services and global theme modifications.

Replace the monolithic behavior of `scripts/rice` with per-feature package
requirements and Arch-specific package/source mappings. Add a Mint adapter
only after checking actual package availability; do not assume an Arch/AUR
package has an identically named `apt` counterpart. Support a clear
prerequisite error or optional feature when none exists.

The installer must be repeatable. On a partial failure, report completed
steps and leave the repository/live files recoverable; do not silently
continue past a required package or ownership conflict.

Acceptance: every implemented profile produces an understandable dry-run plan;
repeated bootstrap is idempotent; mismatched platform/profile refuses to
provision; user-file operations do not need root; profile selection cannot
cause another desktop's files to be deployed or captured.

## Phase 5 — Optional Mint desktop integration

Begin this phase only after the tools-only profile is usable and the target
desktop session has been confirmed. Add `work-mint-cinnamon` as an optional
desktop profile; it composes with the terminal tooling rather than replacing
or delaying it. Replace absolute `/home/nyxze` assumptions with `$HOME` or
XDG paths, and guard distro-specific initialization by checking the actual
file/command.

Add Cinnamon integration incrementally:

1. Respect the existing session, display manager, network/Bluetooth
   applets, notification provider and desktop-managed settings.
2. First recreate only the familiar shortcuts for the terminal, launcher,
   workspaces 1–5 and project launchers using Cinnamon-supported settings or
   commands. Keep window placement manual; do not add automatic application-
   to-workspace rules or copy `hyprctl` dispatches.
3. Add screenshots and other shared user-facing shortcuts after that small
   workspace/launcher milestone is accepted.
4. Apply selected Endfield fonts/icons/colours via documented, narrowly
   owned settings; do not deploy the entire Hyprland GTK/Qt configuration
   as an unreviewed overlay.
5. Add optional GUI applications and platform-specific installation
   sources only when they have been validated on Mint.

Do not install Hyprland, UWSM, Quickshell, Waybar, Hyprlock, Hypridle,
Hyprpaper, SDDM, or the tracked applet-disabling autostart entries just
because those packages appear in the Arch configuration. Feature selection
must be explicit; optional shared GUI tools should remain optional.

Validate file-manager integration separately: the existing Arch setup
provisions Nautilus, while Cinnamon provides Nemo. Do not assume that
Thunar custom actions, Nautilus extensions and Nemo extensions are
interchangeable.

Acceptance: the user can bootstrap the agreed Mint feature set on a fresh
user account, log in normally, access network/Bluetooth and notifications,
use the common terminal/development setup and the agreed shortcuts, manually
place windows in workspaces 1–5, and deploy/capture common changes without
changing any Arch-specific file. Full desktop wallpaper, lock-screen and
theme personalization remain optional and deferred.

## Phase 6 — Regression tests, recovery and maintenance

Build on the existing Hyprland IPC test. Add automated coverage for:

- Manifest/profile validation, package maps and incompatible profile errors.
- Exact source -> destination mapping, XDG paths, selected components and
  duplicate destination detection.
- `--dry-run`, repeatability, `--only` and default active-profile behavior.
- Deploy/capture symmetry, scoped files, modified/untracked content,
  timestamp ties, generated files, exclusions and the deliberate `--force`
  escape hatch.
- Profile transitions: no cross-desktop leak or automatic deletion of
  files owned by a prior profile.
- Failure injection for missing dependencies, failed package installs,
  permission errors and interrupted partial deployment.

Use disposable home directories for file-operation tests and mocks/stubs
for platform package commands. Test actual installation on Arch and Mint
separately. Non-graphical tests do not establish correctness of a live
Hyprland or Cinnamon session; check those in their real desktops.

Document the operator workflow: new-machine bootstrap, ordinary hand edit
and deploy, application-generated change and capture, adding a package,
adding a profile, selecting optional GUI features, clean rollback, and
cleanup of files no longer owned by a profile. Update `AGENTS.md` so
future repository edits follow the new source-of-truth paths.

Acceptance: all automated checks pass, both real-machine checklists pass,
documentation matches implemented CLI behavior, and the legacy
single-machine deployment paths are either removed or explicitly marked
unsupported.

## Cross-phase safety checklist

Before merging any implementation PR:

- [ ] The diff has an explicit scope and does not accidentally alter
      another profile's settings or source files.
- [ ] The current Arch workflow remains usable and has a tested rollback.
- [ ] New dependencies have documented package sources and clear failure
      behavior, including font and external-tool prerequisites.
- [ ] The plan/dry-run reports writes, deletions and privileged actions.
- [ ] Unknown local files, app-managed caches and ignored/private content
      cannot be mirrored or deleted accidentally.
- [ ] Source-of-truth directions and capture rules remain unambiguous.
- [ ] File-based tests pass; live desktop checks are recorded when affected.

## Milestones and PR boundaries

| PR | Scope | Merge gate |
| --- | --- | --- |
| Documentation (this PR) | Architecture and migration contract | Review agrees on boundaries and decisions left open |
| 1 — Terminal tools | `work-mint-tools`, Zsh/Tmux/Yazi, font/palette and portable launcher | Actual work machine is usable without a desktop profile |
| 2 — Inventory | Classify remaining files, dependencies, target paths and baseline | No unowned deployable path |
| 3 — Relayout | Move paths; update *both* sync directions and references | Arch parity and safe round trips |
| 4 — Installer | Profile resolution and platform package adapters | Dry-run/idempotency/privilege checks |
| 5 — Mint desktop | Confirmed-session shortcuts, workspaces and project launchers | Fresh Mint user acceptance with manual placement |
| 6 — Hardening | Regression tests, rollback, operator docs, legacy cleanup | Both platforms pass |

Keep larger feature requests (a fully equivalent Cinnamon panel,
automated visual-theme generation, a universal window-management API or
support for additional architectures) outside the critical migration path.

## Open questions to resolve before implementing them

- Which Linux Mint release and desktop session will the second machine
  actually run, and can its packages or system settings be changed?
- Which optional GUI applications should follow the shared profile, and
  which should remain native desktop defaults?
- Which terminal is already available if Ghostty cannot be installed, and
  which parts of the Endfield font/palette can it represent?
- Should the later Mint desktop work include any Endfield personalization
  beyond the portable terminal/editor palette and fonts?
- Which settings truly need a host-local override instead of a
  distribution/desktop-level definition?
- What is the smallest manifest format that both deploy/capture commands
  and the bootstrap can read without divergent ownership logic?

Resolve these in the relevant implementation PRs with concrete evidence.
They do not block merging the documentation contract.
