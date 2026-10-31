#!/usr/bin/env bash
set -euo pipefail

prompts_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$prompts_dir/providers.sh"
knowledge_file="$prompts_dir/knowledge/AGENTS.md"
state_home=${XDG_STATE_HOME:-$HOME/.local/state}
force=0

if [ "${1-}" = "--force" ]; then
    force=1
    shift
fi

if [ "$#" -eq 0 ]; then
    set -- home codex claude-code opencode
fi

failed=0
for provider in "$@"; do
    target=${KNOWLEDGE_TARGETS[$provider]-}
    if [ -z "$target" ]; then
        echo "✗ $provider: unknown knowledge target" >&2
        failed=1
        continue
    fi

    if [ -L "$target" ] && [ "$(readlink -f -- "$target")" = "$knowledge_file" ]; then
        echo "✓ $provider: $target already points to shared knowledge"
        continue
    fi

    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ "$force" -ne 1 ]; then
            echo "✗ $provider: $target already exists; inspect it before passing --force" >&2
            failed=1
            continue
        fi
        backup_root="$state_home/dotfiles/knowledge-backups"
        mkdir -p "$backup_root"
        backup_dir=$(mktemp -d "$backup_root/$provider.XXXXXX")
        mv -- "$target" "$backup_dir/$(basename "$target")"
        echo "  Backed up $target to $backup_dir"
    fi

    mkdir -p "$(dirname "$target")"
    ln -s "$knowledge_file" "$target"
    echo "✓ $provider: $target -> $knowledge_file"
done

exit "$failed"
