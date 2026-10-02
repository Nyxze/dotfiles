# Repository architecture

This repository currently targets one Arch Linux + Hyprland workstation. The
layout separates user files, system files, package provisioning and repository
tooling without introducing cross-distribution abstractions.

```text
home/                         mirrors paths below $HOME
  .config/                    application configuration
  .local/                     personal scripts, icons and desktop entries
  .zshrc                      shell entry points
  .zsh_profile
  .tmux.conf
  .tmuxrc
platform/arch/                Arch provisioning
  packages/terminal.sh        CLI and development tools
  packages/desktop.sh         GUI and compositor-bound dependencies
profiles/personal-arch.manifest
                              explicit repository-to-home ownership map
system/                       root-owned files, mirroring /
prompts/                      provider-independent skills and agents
scripts/                      repository build and installation helpers
tests/                        non-graphical regression tests
```

## User-file ownership

`profiles/personal-arch.manifest` is the source of truth for paths managed by
`deploy` and `sync-files`. Each entry has one of three modes:

- `mirror`: own an application directory and remove untracked destination
  files after the conflict guard succeeds.
- `scoped`: own only the listed files inside an application-controlled
  directory, leaving caches and history untouched.
- `file`: own one file directly below the home directory.

Both directions consume the same manifest. They retain the checksum and
timestamp guard: a destination change must be captured or deployed before the
opposite direction may overwrite it. `--force` remains an explicit escape
hatch. Documentation, design references and generated caches are excluded from
home deployment.

The repository is the source of truth for hand edits. Application-written
changes can be captured selectively:

```bash
./deploy
./deploy hypr waybar
./sync-files nwg-look
```

## Arch provisioning

The root `install.sh` detects the distribution and is the single bootstrap
entry point. It can be streamed directly on a machine without Git:

```bash
curl -fsSL https://raw.githubusercontent.com/Nyxze/dotfiles/main/install.sh | bash
```

The streamed script installs Git when missing, clones the repository to the
conventional `~/stuff/dotfiles` path, then re-executes itself from that checkout.
On Arch it installs official and AUR packages, deploys the managed home,
installs prompt providers and language toolchains, then publishes the root-owned
configuration. Platform and deployment scripts remain callable on their own for
focused updates.

`platform/arch/packages/terminal.sh` records tools that remain useful without a
graphical session. `platform/arch/packages/desktop.sh` contains GUI applications
and dependencies coupled to Hyprland, Wayland, audio or the desktop session.
`platform/arch/install.sh` combines both inventories for a complete workstation,
performs a full Arch upgrade when official packages are missing, bootstraps
`yay` when necessary, and installs missing packages from both lists. Already
installed packages are not upgraded by a repeated bootstrap. Docker is
installed but its system units remain disabled.

The signed ChatGPT repository bootstrap remains an independent optional step
at `platform/arch/install-chatgpt.sh`; it is not a dotfiles dependency.

Go comes from Arch. Mise installs the pinned global Node.js and Bun versions
declared in `home/.config/mise/config.toml`; project configuration can override
them. Uv manages the pinned default Python toolchain declared in
`home/.config/uv/.python-version`. Pins change deliberately in the repository,
so repeating the bootstrap never upgrades a toolchain implicitly. OpenCode,
Mimiclip and user-installed language binaries remain outside package
provisioning.

Root-owned SDDM files remain under `system/` and are installed separately with
`scripts/install-system.sh`. This keeps package installation, user-file
deployment and privileged system deployment independently reviewable.
