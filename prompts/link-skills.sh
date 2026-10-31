#!/usr/bin/env bash
set -euo pipefail

prompts_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$prompts_dir/providers.sh"
skills_dir="$prompts_dir/skills"
state_home=${XDG_STATE_HOME:-$HOME/.local/state}
force=0
backup_batch=""

if [ "${1-}" = "--force" ]; then
    force=1
    shift
fi

if [ "$#" -eq 0 ]; then
    set -- codex claude-code opencode
fi

backup_target() {
    local provider="$1" target="$2" backup_parent
    if [ -z "$backup_batch" ]; then
        mkdir -p "$state_home/dotfiles/skill-backups"
        backup_batch=$(mktemp -d "$state_home/dotfiles/skill-backups/install.XXXXXX")
    fi
    backup_parent="$backup_batch/$provider"
    mkdir -p "$backup_parent"
    mv -- "$target" "$backup_parent/$(basename "$target")"
}

failed=0
for provider in "$@"; do
    target_root=${SKILL_TARGETS[$provider]-}
    if [ -z "$target_root" ]; then
        echo "✗ $provider: unknown skill target" >&2
        failed=1
        continue
    fi
    mkdir -p "$target_root"

    while IFS= read -r -d '' skill_dir; do
        [ -f "$skill_dir/SKILL.md" ] || continue
        target="$target_root/$(basename "$skill_dir")"
        if [ -L "$target" ] && [ "$(readlink -f -- "$target")" = "$skill_dir" ]; then
            continue
        fi

        if [ -e "$target" ] || [ -L "$target" ]; then
            if [ "$force" -ne 1 ] && ! diff -qr -- "$skill_dir" "$target" >/dev/null 2>&1; then
                echo "✗ $provider: $target differs from the shared skill; inspect it before passing --force" >&2
                failed=1
                continue
            fi
            backup_target "$provider" "$target"
        fi

        ln -s "$skill_dir" "$target"
        echo "✓ $provider: $(basename "$skill_dir") -> $skill_dir"
    done < <(find "$skills_dir" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

    while IFS= read -r -d '' target; do
        linked=$(readlink -- "$target")
        case "$linked" in
            "$skills_dir/"*)
                if [ ! -e "$linked" ]; then
                    unlink -- "$target"
                    echo "✓ $provider: removed stale $(basename "$target") link"
                fi
                ;;
        esac
    done < <(find "$target_root" -mindepth 1 -maxdepth 1 -type l -print0)
done

if [ -n "$backup_batch" ]; then
    echo "Previous skill directories: $backup_batch"
fi

exit "$failed"
