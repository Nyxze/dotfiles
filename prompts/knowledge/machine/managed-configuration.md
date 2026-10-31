# Managed machine configuration

This procedure applies in every project and session when changing OS, desktop,
shell, lock screen, or other personal machine configuration. The source of truth
is the repository containing the canonical `prompts/knowledge/AGENTS.md` that
links to this page; files under the home directory are deployed copies. Resolve
the provider's global instruction symlink to find that repository, then work
there even when the request arrives elsewhere. For example, the default home
entrypoint can be resolved with
`git -C "$(dirname "$(readlink -f "$HOME/AGENTS.md")")" rev-parse --show-toplevel`.
Run the commands below from that repository root. If it is unavailable, ask the
user to open or restore it instead of editing live configuration.

## Required sequence

1. Identify the active profile and the owning file in `home/common/` or its
   profile overlay (`home/arch-hyprland/` or `home/mint-xfce/`). Inspect the
   source, live copy, and `$XDG_STATE_HOME/dotfiles/deployed-files/PROFILE`
   before changing anything. Preserve unrelated working-tree and live changes.
2. Reconcile preexisting drift. When the live file contains the desired change
   and the repository file still matches the last synchronized checksum, use
   `./capture-config --profile PROFILE .config/path/to/file`. If both sides
   changed, merge the intended state into the owning repository file. Do not
   discard either version silently.
3. Edit the owning repository file. Create new files there. Never edit a managed
   live path directly, even for a temporary test or an urgent fix.
4. Apply only the intended paths with
   `./apply-config --profile PROFILE .config/path/to/file`. Use a component name
   only when every file in that component belongs to the change. The command
   refuses an overwrite when a live file differs from the last synchronized
   copy. Do not use `--force` without the user's explicit choice to discard
   that version.
5. Confirm the source and deployed files match. Check the dependent service and
   behavior; a successful copy alone is insufficient. Run visual tests on a
   separate display. Restart a running desktop component only when needed,
   through its persistent service or a detached launch, and confirm it remains
   running after the command session ends.
6. Commit and push the repository change, excluding unrelated working-tree edits.
   The change is complete when the source is synchronized and the current
   machine runs that source.

Global agent instructions are an exception to the copied `home/` layers. Edit
`prompts/knowledge/AGENTS.md` or its references; provider entrypoints link to
that shared source through `prompts/link-knowledge.sh`.
