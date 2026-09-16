#!/usr/bin/env bash
# What the two directions have to agree on: which directory each provider
# scans, and when a copy must refuse to run. scripts/install.sh carries
# prompts/ out to the providers, sync-skills.sh brings back what a tool wrote
# on its own; both source this file, so a new provider is one entry here and
# both directions pick it up.

# prompts/ subdirectory -> the directory that provider scans.
#
# opencode reads .opencode/skills relative to the working directory, walking up
# no further than the git worktree, and ~/.config/opencode/skills is its only
# global location. Skills placed under ~/.opencode therefore load only while the
# working directory is the home directory itself, which is why they look
# installed and are not.
declare -A PROVIDERS=(
    [claude-code]="skills:$HOME/.claude/skills agents:$HOME/.claude/agents"
    [opencode]="skills:$HOME/.config/opencode/skills agents:$HOME/.config/opencode/agent"
)

# A provider that reads a different format needs a translation rather than a
# copy, and the entry names the script that writes that destination.
#
# An adapted destination is generated: written from prompts/, never read back.
# A conversion cannot be reversed faithfully, so there is nothing to capture
# there and no guard to run — an edit made in one of those directories is lost
# on the next install, which is why the script names them out loud.
declare -A ADAPTERS=(
    [opencode:agents]="adapters/opencode-agents.py"
)

# Both directions delete, so each refuses while the other side holds something
# it would destroy. Tools write into the directories they scan — skill-creator
# drops new skills straight into ~/.claude/skills — and --delete would carry
# those off without a word.
#
# A checksum difference is symmetric and says nothing about which side moved,
# so the modification time breaks the tie, and only one way: a copy preserves
# the source mtime, so a same-second edit on the other side lands on an equal
# timestamp that no comparison can separate. Anything not strictly older than
# its destination therefore counts as never replayed, and the copy refuses
# rather than guess.
pending() {
    local src="$1" dst="$2" rel out=""
    while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        [ -e "$dst/$rel" ] || continue
        if [ ! -e "$src/$rel" ]; then
            out+="$rel (exists only there)"$'\n'
        elif [ ! "$src/$rel" -nt "$dst/$rel" ]; then
            out+="$rel"$'\n'
        fi
    done < <(rsync -rn -i --delete --checksum "$src/" "$dst/" 2>/dev/null \
                 | grep -E '^(>|<|\*deleting)' | sed -E 's/^\S+[[:space:]]+//')
    printf '%s' "$out"
}

# $4 is how the other direction replays what would be lost, printed in the
# refusal so the way out is on screen.
guard() {
    local label="$1" src="$2" dst="$3" replay="$4" lost
    [ -d "$dst" ] || return 0
    lost=$(pending "$src" "$dst")
    [ -n "$lost" ] || return 0

    echo "✗ $label: the destination holds changes the source does not."
    echo "$lost" | sed 's/^/    /'
    echo "  $replay,"
    echo "  or pass --force to discard them."
    return 1
}

# Every "kind:path" pair of a provider, or only those of the given kind.
provider_entries() {
    local provider="$1" kind="${2-}" entry
    for entry in ${PROVIDERS[$provider]}; do
        [ -z "$kind" ] || [ "${entry%%:*}" == "$kind" ] || continue
        echo "$entry"
    done
}
