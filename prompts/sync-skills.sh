#!/usr/bin/env bash
# sync-skills.sh — Sync local provider skills into the dotfiles repo.
# Sources (last wins): ~/.opencode/skills, ~/.claude/skills
# Destination: ~/stuff/dotfiles/prompts/skills

DEST="$HOME/stuff/dotfiles/prompts/skills"
SOURCES=(
  "$HOME/.opencode/skills"
  "$HOME/.claude/skills"
)
DRY_RUN=false
[[ "$1" == "--dry-run" || "$1" == "-n" ]] && DRY_RUN=true

rsync_opts="-a --delete"
$DRY_RUN && rsync_opts="$rsync_opts --dry-run"

declare -A seen  # track which skills have been processed

for source in "${SOURCES[@]}"; do
  [[ ! -d "$source" ]] && continue

  for skill_path in "$source"/*/; do
    skill=$(basename "$skill_path")
    dest_path="$DEST/$skill"
    label="(from $source)"

    if [[ -d "$dest_path" ]]; then
      action="[UPDATE]"
      [[ -n "${seen[$skill]}" ]] && label="$label [overrides ${seen[$skill]}]"
    else
      action="[CREATE]"
    fi

    echo "$action $skill $label"
    $DRY_RUN || rsync $rsync_opts "$skill_path" "$dest_path/"
    seen[$skill]="$source"
  done
done
