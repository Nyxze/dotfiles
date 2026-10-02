#!/usr/bin/env bash

documentation_file() {
    case "$1" in
        */AGENTS.md|*/DESIGN.md|*/README.md|*/TODO.md|*/CLAUDE.md|*.pdf|*/icon-theme.cache) return 0 ;;
    esac
    return 1
}

component_for() {
    local path="$1"
    case "$path" in
        .config/*) printf '%s\n' "${path#.config/}" | cut -d/ -f1 ;;
        .local/scripts/*) printf '%s\n' scripts ;;
        .local/share/icons/endfield/*) printf '%s\n' icons ;;
        .local/share/applications/*) printf '%s\n' applications ;;
        .*) basename "$path" | sed 's/^\.//' ;;
        *) printf '%s\n' "${path%%/*}" ;;
    esac
}

detect_profile() {
    if [ -n "${DOTFILES_PROFILE:-}" ]; then
        printf '%s\n' "$DOTFILES_PROFILE"
        return
    fi

    if [ ! -r /etc/os-release ]; then
        echo "Cannot select a dotfiles profile: /etc/os-release is missing." >&2
        return 1
    fi

    # shellcheck disable=SC1091
    source /etc/os-release
    case "${ID,,}" in
        arch) printf '%s\n' arch-hyprland ;;
        linuxmint) printf '%s\n' mint-xfce ;;
        *)
            echo "No dotfiles profile for ${PRETTY_NAME:-$ID}. Use --profile." >&2
            return 1
            ;;
    esac
}

usage() {
    cat <<'EOF'
Usage: apply-config|capture-config [--profile PROFILE] [--force] [COMPONENT ...]

Apply common files followed by PROFILE, or capture live changes into the layer
that owns them. PROFILE defaults to the detected distribution. Components are
top-level configuration names such as quickshell, hypr, i3, or scripts.
EOF
}

selected() {
    local component="$1" filter
    [ "${#FILTERS[@]}" -eq 0 ] && return 0
    for filter in "${FILTERS[@]}"; do
        [ "$filter" = "$component" ] && return 0
    done
    return 1
}

mark_seen() {
    local component="$1" filter
    for filter in "${FILTERS[@]}"; do
        [ "$filter" = "$component" ] && SEEN["$filter"]=1
    done
}

guard_file() {
    local label="$1" source="$2" destination="$3"
    [ -e "$destination" ] || return 0
    cmp -s "$source" "$destination" && return 0
    [ "$source" -nt "$destination" ] && return 0

    echo "✗ $label: the destination differs and is not older."
    echo "  Run the opposite direction first, or pass --force to discard it."
    return 1
}

file_hash() {
    sha256sum "$1" | awk '{print $1}'
}

collect_layer() {
    local root="$1" layer="$2" sources_name="$3" layers_name="$4"
    local -n layer_sources="$sources_name" layer_names="$layers_name"
    local layer_root="$root/home/$layer" source relative
    [ -d "$layer_root" ] || return 0

    while IFS= read -r -d '' source; do
        relative=${source#"$layer_root/"}
        documentation_file "$relative" && continue
        layer_sources["$relative"]="$source"
        layer_names["$relative"]="$layer"
    done < <(find "$layer_root" -type f -print0 | sort -z)
}

load_state() {
    local file="$1" state_name="$2" relative hash
    local -n state="$state_name"
    [ -r "$file" ] || return 0
    while IFS=$'\t' read -r relative hash; do
        [ -n "$relative" ] && [ -n "$hash" ] && state["$relative"]="$hash"
    done < "$file"
}

write_state() {
    local file="$1" state_name="$2" state_dir relative temporary
    local -n state="$state_name"
    state_dir=$(dirname "$file")
    mkdir -p "$state_dir"
    temporary=$(mktemp "$state_dir/.deployed-files.XXXXXX")
    for relative in "${!state[@]}"; do
        printf '%s\t%s\n' "$relative" "${state[$relative]}"
    done | sort >"$temporary"
    mv "$temporary" "$file"
}

run_deploy() {
    local repo_root="$1" profile="$2" state_file="$3"
    local -A sources=() layers=() previous=() next=()
    local relative source destination component failed=0

    collect_layer "$repo_root" common sources layers
    collect_layer "$repo_root" "$profile" sources layers
    load_state "$state_file" previous
    for relative in "${!previous[@]}"; do
        next["$relative"]="${previous[$relative]}"
    done

    for relative in "${!sources[@]}"; do
        component=$(component_for "$relative")
        selected "$component" || continue
        mark_seen "$component"
        source=${sources[$relative]}
        destination="$HOME/$relative"
        if [ "$FORCE" -ne 1 ] && ! guard_file "$component: $relative" "$source" "$destination"; then
            failed=1
        fi
    done

    for relative in "${!previous[@]}"; do
        [ -n "${sources[$relative]+x}" ] && continue
        component=$(component_for "$relative")
        selected "$component" || continue
        mark_seen "$component"
        destination="$HOME/$relative"
        [ -e "$destination" ] || continue
        if [ "$FORCE" -ne 1 ] && [ "$(file_hash "$destination")" != "${previous[$relative]}" ]; then
            echo "✗ $component: $relative was changed outside the repository."
            echo "  Pass --force to remove the file created by an earlier deployment."
            failed=1
        fi
    done

    [ "$failed" -eq 0 ] || return 1

    for relative in "${!sources[@]}"; do
        component=$(component_for "$relative")
        selected "$component" || continue
        source=${sources[$relative]}
        destination="$HOME/$relative"
        mkdir -p "$(dirname "$destination")"
        rsync -a "$source" "$destination"
        next["$relative"]="$(file_hash "$source")"
        echo "✓ $component: $relative (${layers[$relative]})"
    done

    for relative in "${!previous[@]}"; do
        [ -n "${sources[$relative]+x}" ] && continue
        component=$(component_for "$relative")
        selected "$component" || continue
        destination="$HOME/$relative"
        if [ ! -e "$destination" ]; then
            unset 'next[$relative]'
            continue
        fi
        rm -f -- "$destination"
        unset 'next[$relative]'
        echo "✓ removed $component: $relative"
    done

    write_state "$state_file" next
}

run_capture() {
    local repo_root="$1" profile="$2"
    local -A sources=() layers=()
    local relative source destination component failed=0

    collect_layer "$repo_root" common sources layers
    collect_layer "$repo_root" "$profile" sources layers

    for relative in "${!sources[@]}"; do
        component=$(component_for "$relative")
        selected "$component" || continue
        mark_seen "$component"
        source="$HOME/$relative"
        destination=${sources[$relative]}
        [ -e "$source" ] || continue
        if [ "$FORCE" -ne 1 ] && ! guard_file "$component: $relative" "$source" "$destination"; then
            failed=1
        fi
    done

    [ "$failed" -eq 0 ] || return 1

    for relative in "${!sources[@]}"; do
        component=$(component_for "$relative")
        selected "$component" || continue
        source="$HOME/$relative"
        destination=${sources[$relative]}
        [ -e "$source" ] || continue
        rsync -a "$source" "$destination"
        echo "✓ $component: $relative (${layers[$relative]})"
    done
}

run_managed_home() {
    local direction="$1" repo_root="$2" profile="" state_file filter
    shift 2

    FORCE=0
    FILTERS=()
    declare -gA SEEN=()
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --force) FORCE=1 ;;
            --profile)
                shift
                [ "$#" -gt 0 ] || { echo "--profile needs a value." >&2; return 2; }
                profile="$1"
                ;;
            -h|--help) usage; return 0 ;;
            --*) echo "Unknown option: $1" >&2; usage >&2; return 2 ;;
            *) FILTERS+=("$1") ;;
        esac
        shift
    done

    profile=${profile:-$(detect_profile)} || return 1
    if [ ! -d "$repo_root/home/$profile" ]; then
        echo "Unknown profile: $profile" >&2
        return 2
    fi

    state_file="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/deployed-files/$profile"
    case "$direction" in
        deploy) run_deploy "$repo_root" "$profile" "$state_file" ;;
        capture) run_capture "$repo_root" "$profile" ;;
        *) echo "Unknown managed-home direction: $direction" >&2; return 2 ;;
    esac || return $?

    for filter in "${FILTERS[@]}"; do
        [ -n "${SEEN[$filter]+x}" ] || {
            echo "✗ $filter: not managed by profile $profile"
            return 1
        }
    done
}
