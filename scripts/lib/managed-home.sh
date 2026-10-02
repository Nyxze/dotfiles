#!/usr/bin/env bash

DOCS=(--exclude=AGENTS.md --exclude=DESIGN.md --exclude=README.md
      --exclude=TODO.md --exclude=CLAUDE.md --exclude='*.pdf'
      --exclude=icon-theme.cache)

selected() {
    local name="$1" filter
    [ ${#FILTERS[@]} -eq 0 ] && return 0
    for filter in "${FILTERS[@]}"; do
        [ "$filter" = "$name" ] && return 0
    done
    return 1
}

mark_seen() {
    local name="$1" filter
    for filter in "${FILTERS[@]}"; do
        [ "$filter" = "$name" ] && SEEN["$filter"]=1
    done
}

pending_tree() {
    local src="$1" dst="$2" rel out=""
    while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        [ -e "$dst/$rel" ] || continue
        if [ ! -e "$src/$rel" ]; then
            out+="$rel (exists only there)"$'\n'
        elif [ ! "$src/$rel" -nt "$dst/$rel" ]; then
            out+="$rel"$'\n'
        fi
    done < <(rsync -rn -i --delete --checksum "${DOCS[@]}" "$src/" "$dst/" 2>/dev/null \
                 | grep -E '^(>|<|\*deleting)' | sed -E 's/^\S+[[:space:]]+//')
    printf '%s' "$out"
}

guard_tree() {
    local label="$1" src="$2" dst="$3" lost
    [ -d "$dst" ] || return 0
    lost=$(pending_tree "$src" "$dst")
    [ -n "$lost" ] || return 0

    echo "✗ $label: the destination holds changes the source does not."
    echo "$lost" | sed 's/^/    /'
    echo "  Run the opposite direction first, or pass --force to discard them."
    return 1
}

guard_file() {
    local label="$1" src="$2" dst="$3"
    [ -e "$dst" ] || return 0
    cmp -s "$src" "$dst" && return 0
    [ "$src" -nt "$dst" ] && return 0

    echo "✗ $label: the destination differs and is not older."
    echo "  Run the opposite direction first, or pass --force to discard it."
    return 1
}

copy_file() {
    local label="$1" src="$2" dst="$3"
    [ -e "$src" ] || { echo "✗ $label: source not found: $src"; return 1; }
    [ "$FORCE" = 1 ] || guard_file "$label" "$src" "$dst" || return 1
    mkdir -p "$(dirname "$dst")"
    rsync -a "$src" "$dst"
    echo "✓ $label"
}

copy_scoped() {
    local label="$1" src="$2" dst="$3"; shift 3
    local rel blocked=0 moved=0
    for rel in "$@"; do
        [ -e "$src/$rel" ] || continue
        if [ "$FORCE" != 1 ] && ! guard_file "$label: $rel" "$src/$rel" "$dst/$rel"; then
            blocked=1
            continue
        fi
        mkdir -p "$dst/$(dirname "$rel")"
        rsync -a "$src/$rel" "$dst/$rel"
        moved=$((moved + 1))
    done
    [ $blocked = 0 ] || return 1
    echo "✓ $label ($moved file(s))"
}

copy_mirror() {
    local label="$1" src="$2" dst="$3"
    [ -d "$src" ] || { echo "✗ $label: source not found: $src"; return 1; }
    [ "$FORCE" = 1 ] || guard_tree "$label" "$src" "$dst" || return 1
    mkdir -p "$dst"
    rsync -a --delete "${DOCS[@]}" "$src/" "$dst/"
    echo "✓ $label"
}

run_managed_home() {
    local direction="$1" repo_root="$2" manifest="$3" mode name repo_path home_path managed
    shift 3

    FORCE=0
    FILTERS=()
    declare -gA SEEN=()
    while [ $# -gt 0 ]; do
        if [ "$1" = --force ]; then
            FORCE=1
        else
            FILTERS+=("$1")
        fi
        shift
    done

    FAILED=0
    while read -r mode name repo_path home_path managed; do
        [ -n "$mode" ] || continue
        [[ "$mode" = \#* ]] && continue
        selected "$name" || continue
        mark_seen "$name"

        local repo_source="$repo_root/$repo_path"
        local home_source="$HOME/$home_path"
        local src="$repo_source" dst="$home_source"
        if [ "$direction" = capture ]; then
            src="$home_source"
            dst="$repo_source"
        fi

        case "$mode" in
            mirror) copy_mirror "$name" "$src" "$dst" || FAILED=1 ;;
            file) copy_file "$name" "$src" "$dst" || FAILED=1 ;;
            scoped)
                read -r -a managed_paths <<<"$managed"
                copy_scoped "$name" "$src" "$dst" "${managed_paths[@]}" || FAILED=1
                ;;
            *) echo "✗ $name: unknown manifest mode: $mode"; FAILED=1 ;;
        esac
    done < "$manifest"

    local filter
    for filter in "${FILTERS[@]}"; do
        [ -n "${SEEN[$filter]+x}" ] || { echo "✗ $filter: not managed by this profile"; FAILED=1; }
    done
    return "$FAILED"
}
