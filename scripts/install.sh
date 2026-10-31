#!/usr/bin/env bash
# Repository -> providers. Personal skills and global instructions are linked;
# provider-specific agents are copied or converted.
#
#   ./scripts/install.sh                 every provider
#   ./scripts/install.sh claude-code     just this one
#   ./scripts/install.sh --force         discard whatever the providers hold

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_DIR="$(dirname "$SCRIPT_DIR")/prompts"
source "$PROMPTS_DIR/providers.sh"

install_provider() {
    local provider="$1" entry kind src dest adapter summary

    if [ -z "${PROVIDERS[$provider]+x}" ]; then
        echo "✗ $provider: not a known provider"
        FAILED=1
        return
    fi

    while IFS= read -r entry; do
        kind="${entry%%:*}"
        dest="${entry#*:}"
        src="$PROMPTS_DIR/$kind"

        if [ ! -d "$src" ]; then
            echo "✗ $provider: prompts/$kind does not exist"
            FAILED=1
            continue
        fi

        adapter="${ADAPTERS[$provider:$kind]-}"
        if [ -n "$adapter" ]; then
            mkdir -p "$dest"
            if summary=$("$PROMPTS_DIR/$adapter" "$src" "$dest"); then
                echo "✓ $provider: $kind -> $dest ($summary)"
            else
                echo "✗ $provider: $kind: $adapter failed"
                FAILED=1
            fi
            continue
        fi

        [ "$FORCE" = 1 ] \
            || guard "$provider ($kind)" "$src" "$dest" "Capturing them first: ./prompts/capture.sh" \
            || { FAILED=1; continue; }

        mkdir -p "$dest"
        rsync -a --delete --exclude='.gitkeep' "$src/" "$dest/"
        echo "✓ $provider: $kind -> $dest"
    done < <(provider_entries "$provider")
}

FORCE=0
FAILED=0
args=()
for a in "$@"; do
    [ "$a" == "--force" ] && FORCE=1 || args+=("$a")
done

[ ${#args[@]} -gt 0 ] || args=("${!PROVIDERS[@]}")
for provider in "${args[@]}"; do
    install_provider "$provider"
done

if [ "$FORCE" = 1 ]; then
    "$PROMPTS_DIR/link-skills.sh" --force "${args[@]}" || FAILED=1
else
    "$PROMPTS_DIR/link-skills.sh" "${args[@]}" || FAILED=1
fi

knowledge_args=(home "${args[@]}")
if [ "$FORCE" = 1 ]; then
    "$PROMPTS_DIR/link-knowledge.sh" --force "${knowledge_args[@]}" || FAILED=1
else
    "$PROMPTS_DIR/link-knowledge.sh" "${knowledge_args[@]}" || FAILED=1
fi

exit $FAILED
