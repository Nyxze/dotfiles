# Multi-distribution dotfiles: target architecture

Status: **proposed**. This document defines the target state, not an implemented interface.
See [the migration plan](multidistro-migration.md) for the implementation sequence
and acceptance criteria.

## Goals and boundaries

Support the existing Arch Linux + Hyprland desktop and an employer-provided
Linux Mint machine from one repository. Cinnamon is the working assumption,
not a confirmed requirement: its release, desktop session and the permission to
install packages or change system settings must be established on the machine.
The two machines should share terminal, development and other genuinely
portable configuration without sharing compositor-specific behavior. Adding
another distribution or desktop should mean adding an adapter or profile, not
copying the entire repository.

Preserve the existing contract: the repository is the source of truth for hand
edits; `deploy` copies repository -> machine; `sync-files` captures
application-written changes machine -> repository. The current conflict guards,
scoped-file handling, documentation exclusions and deliberate treatment of
generated files must survive the migration.

This is **not** an OS installer, a guarantee that all applications are available
on every distribution, an attempt to make Hyprland and a Mint desktop behave
identically, or a request to replace the current copy-based deployment with
symlinks, Stow, Nix or another configuration manager. No machine or source
files are changed by this document.

## Independent axes

| Axis | Meaning | Initial values |
| --- | --- | --- |
| Common | Application configuration that can be copied unchanged between hosts | Zsh, Neovim, Tmux, Yazi, terminal theme/font data, selected scripts |
| Desktop | Optional session-specific components, controls and integration | `hyprland`, `cinnamon` if confirmed |
| Platform | Distribution-specific provisioning and system integration | `arch`, `mint` |
| Profile | Explicit composition of common + platform + optional desktop + selected features | `personal-arch`, `work-mint-tools` |
| Host (only if needed) | Overrides for physical displays, devices, local paths or policy | A local, untracked host file |

A distribution does not imply a desktop. A package manager is part of the
platform; Hyprland IPC, shortcuts and session services are part of the desktop.
CPU architecture (`x86_64`, `aarch64`, etc.) is another possible constraint
for packages, not a substitute for either axis.

A profile must select exactly one platform. It may select zero or one desktop:
`work-mint-tools` is a valid tools-only profile and must deploy/capture terminal
tooling without desktop settings or session activation. Common components and
optional features may be selected independently. The profile is explicit;
detection can validate it, but must not silently choose one because `pacman` or
`apt` happens to be installed.

## Proposed repository layout

Paths below describe the desired organization. They are **not** current paths.

```text
common/
  .config/{nvim,zsh,tmux,ghostty,yazi,btop,Code,opencode,rofi,...}/
  .local/scripts/                 # compositor-independent commands only
  .zshrc
  .zsh_profile
  .tmux.conf
  .tmuxrc

desktop/
  hyprland/
    .config/{hypr,waybar,quickshell,...}/
    .config/autostart/            # Hyprland-specific applet suppression
    .local/scripts/              # e.g. preview
    .local/share/applications/   # desktop-specific launchers
  cinnamon/
    config/                       # only settings we explicitly own
    scripts/                      # desktop-specific helpers, if required

platform/
  arch/                           # pacman/yay mappings and Arch operations
  mint/                           # apt/other source mappings and Mint operations

profiles/
  personal-arch.*                 # common + arch + hyprland + selected features
  work-mint-tools.*               # common + mint, no desktop selection
  work-mint-cinnamon.*            # optional, after Cinnamon is confirmed

system/
  sddm/                           # root-owned, selected by a feature/profile

prompts/                           # existing provider-specific skills/agents
scripts/                           # bootstrap, deployment helpers, build tooling
docs/
tests/
bootstrap
deploy
sync-files
```

The notation `.*` intentionally leaves the manifest format undecided.
Choose it in the bootstrap PR after comparing a simple declarative format
against the needs of the existing Bash scripts. Do not create a general-purpose
configuration language.

The directory tree is a *source* layout, not the shape of `$HOME`.
The installation manifest maps each selected path to its real destination:
`common/.config/nvim/` -> `~/.config/nvim/`, for example, and
`desktop/hyprland/.config/hypr/` -> `~/.config/hypr/`.
Honor `XDG_CONFIG_HOME` and `XDG_DATA_HOME` where applicable.

Keep `prompts/` and the existing provider installation/capture workflow
separate: these are shared across systems but have provider-owned destinations
and adapter semantics rather than ordinary `~/.config` mirrors.

## Initial classification of existing files

This classification is a migration starting point; Phase 2 verifies actual
runtime dependencies and identifies any files requiring a finer split.

| Current source | Proposed owner | Notes |
| --- | --- | --- |
| `.config/nvim`, `.config/yazi`, `.config/tmux`, `.config/btop`, `.config/zsh` | Common | Keep their existing application paths. |
| `.config/ghostty`, `.config/ghostty/themes/endfield` | Common optional terminal component | Ghostty uses `NotoMono Nerd Font` and the Endfield palette. Install that font when Ghostty is enabled; otherwise apply the same palette/font intent through an adapter for the available terminal. |
| `.config/rofi`, `.config/theme/rofi-tail.png` | Common optional launcher component | Rofi is not Hyprland-only. Keep its portable configuration/theme with application components; keep Hyprland bindings, Quickshell hand-off and other session integration under the desktop. Replace the current hard-coded artwork path with an XDG/home-relative generated path before cross-host deployment. |
| `.zshrc`, `.zsh_profile`, `.tmux.conf`, `.tmuxrc` | Common | First remove absolute home paths and guard platform-installed initialization. |
| `.config/Code`, `.config/opencode` | Common, scoped | Preserve the explicit file allowlist; do not mirror caches/history or `node_modules`. |
| `.local/scripts` | Split | SSH/Tmux/Git helpers may be common; `preview` requires Hyprland IPC and belongs to that desktop. Inspect every script before moving it. |
| `.config/hypr`, `.config/quickshell`, `.config/waybar`, `.config/nwg-*`, `.config/cliphist` | Primarily Hyprland | Reassess individual portable pieces; do not install these wholesale on Mint. |
| `.config/autostart` | Hyprland | The tracked `Hidden=true` entries disable `nm-applet` and `blueman-applet`; do not export them to Cinnamon. |
| `.config/gtk-3.0`, `.config/gtk-4.0`, `.config/qt5ct`, `.config/qt6ct`, `.config/fontconfig` | Shared assets + explicitly selected GUI feature/desktop overrides | Do not overwrite Cinnamon's desktop-managed defaults merely because GTK/Qt exists on both systems. |
| `.config/theme`, Ghostty/Yazi themes, `.local/share/icons/endfield` | Shared design assets, applied by selected features | Keep Endfield consistent without requiring Cinnamon to use every Hyprland styling mechanism. |
| `.config/Thunar` | Optional application feature | Do not assume the file manager is the same: current Arch provisioning uses Nautilus; Mint/Cinnamon normally provides Nemo. |
| `.local/share/applications/endfield-shortcuts.desktop` | Hyprland | Currently calls the Quickshell shortcut panel. |
| `system/sddm` and `scripts/install-system.sh` | Optional SDDM feature | Only install when the selected profile explicitly enables SDDM. Mint should retain its existing display manager by default. |
| `scripts/rice` | Split between platform and desktop feature dependencies | Currently interleaves `pacman`, `yay`, GTK settings, service masking and desktop setup. |
| `install-arch.sh` | Out of scope until classified | Currently installs the ChatGPT Arch package; it is not the general dotfiles bootstrap. |

An application's configuration need not be portable just because the binary
is available on both distributions. Cross-desktop GUI configuration must be
opted into explicitly.

## Profile resolution and deployment

A future bootstrap can expose the following **proposed**, not yet implemented,
interface:

```bash
./bootstrap --profile personal-arch
./bootstrap --profile work-mint-tools
./deploy --profile work-mint-tools --dry-run
./deploy --profile work-mint-tools --only tmux
./sync-files --profile work-mint-tools --only tmux
```

After bootstrap, persist the active profile locally in an ignored state file.
Without `--profile`, deployment and capture use that selection. An explicit
profile flag remains available for inspection and testing. An incompatible
platform/profile pairing must fail *before* privileged operations.

A single resolved manifest must drive **both** deployment directions. For each
component it records a source, destination, ownership mode and optional list
of managed files. Directory mirrors, single files, scoped application files,
generated artifacts and privileged system files have different policies.
Treat unknown destinations and overlapping ownership as errors, not as
last-writer-wins overlays. An override must name the precise files it replaces.
The tools-only profile uses this same manifest contract; it is not a separate,
less safe deployment path.

The default deploy/capture operation must touch only paths belonging to the
active profile. Never discover all repository directories and assume they are
installed. Preserve the existing checks against overwriting changes on the
opposite side; keep `--force` explicit and scoped. A profile change may leave
previously installed managed files behind: show an ownership-aware cleanup plan
rather than deleting unrelated or user-created content automatically.

For generated files (e.g. compiled shaders or the derived SDDM theme), define
the original source and build step; do not capture generated output as an
independent user edit. Preserve the existing `prompts/` adaptation contract.

## Provisioning and privilege boundaries

Define dependencies by component or capability (common CLI tools, editors,
terminal/font, Hyprland session, Endfield artwork, optional desktop
integrations), then map them to the platform's actual package names and
sources. `pacman`/`yay` and `apt` are implementations, not calls scattered
through common scripts. Verify package availability and naming on the target
Mint release before committing a package map; record any packages needing a
third-party source or manual installation. If employer policy prevents package
installation, report the missing prerequisite and deploy only components whose
requirements are already met.

Provisioning should be idempotent and support a plan/dry-run. Keep package
installation, per-user configuration, root-owned system changes and session
activation separate. Run user-file deployment without `sudo`. Require an
explicit selection and confirmation for changes such as SDDM installation,
service masking or system-wide icon-theme modification. A tools-only profile
has no desktop session activation step.

Desktop-specific preferences should be narrowly applied. If Cinnamon is the
target, it may manage shortcuts and themes through GSettings/dconf: record the
keys owned by the profile and avoid whole-database imports or indiscriminate
overwrites.

## Invariants for implementation

- A common edit has one canonical repository path, independently deployable
  to Arch and Mint; a desktop-specific edit cannot leak across profiles.
- A full deploy/sync operates only on the active profile's owned paths.
- Neither direction silently discards modifications, caches, history, unknown
  files, user settings or files owned by another profile.
- Running bootstrap/deploy twice is safe and produces no unexpected changes.
- Root access is restricted to explicit system operations.
- Existing Arch + Hyprland behavior and the Endfield visual identity survive
  the restructure; Mint does not lose its native network/Bluetooth agents.
- A platform-selected tools-only profile deploys and captures terminal tooling
  without selecting, modifying or activating a desktop session.
- Every package used by an enabled feature has a documented installation
  source or a clear, testable prerequisite failure.
- Tests validate the resolved file/ownership plan without requiring a running
  graphical session; desktop-specific behavior also receives live checks.

Unresolved choices (manifest serialization, the exact optional feature list,
the Mint release, desktop session, package sources and whether the work
machine permits provisioning) are tracked in the migration plan rather than
silently assumed here.
