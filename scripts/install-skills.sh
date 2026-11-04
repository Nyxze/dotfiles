#!/usr/bin/env bash
# Install only the personal skills from prompts/skills.
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

usage() {
    cat <<'EOF'
Usage: ./scripts/install-skills.sh [--provider PROVIDER]... [--force]

Link every personal skill into the selected provider's global skills directory.
With no provider and a terminal, choose from a small menu. No other agent
configuration is installed.

Providers: codex, claude-code, opencode, all

Options:
  --provider, --agent PROVIDER  Select a provider; repeat for multiple tools
  --force                       Back up conflicting skill directories and relink
  -h, --help                    Show this help

Examples:
  ./scripts/install-skills.sh
  ./scripts/install-skills.sh --provider all
  ./scripts/install-skills.sh --provider codex --provider opencode
EOF
}

providers=()
force=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --force)
            force=1
            ;;
        --provider|--agent)
            shift
            if [ "$#" -eq 0 ]; then
                echo "Missing value for --provider. Use --help for usage." >&2
                exit 2
            fi
            providers+=("$1")
            ;;
        *)
            echo "Unknown argument: $1. Use --help for usage." >&2
            exit 2
            ;;
    esac
    shift
done

if [ "${#providers[@]}" -eq 0 ]; then
    if [ ! -t 0 ] || [ ! -t 2 ]; then
        echo "Select a provider with --provider codex|claude-code|opencode|all in non-interactive mode." >&2
        exit 2
    fi
    printf 'Install shared skills for:\n' >&2
    printf '  1) All providers (Codex, Claude Code, OpenCode)\n' >&2
    printf '  2) Codex\n  3) Claude Code\n  4) OpenCode\n  0) Cancel\n' >&2
    printf 'Choice [1]: ' >&2
    IFS= read -r choice || exit 0
    case "$choice" in
        ''|1) providers=(all) ;;
        2) providers=(codex) ;;
        3) providers=(claude-code) ;;
        4) providers=(opencode) ;;
        0|q|Q) exit 0 ;;
        *) echo "Invalid choice: $choice" >&2; exit 2 ;;
    esac
fi

selected=()
declare -A seen=()
for provider in "${providers[@]}"; do
    if [ "$provider" = all ]; then
        if [ "${#providers[@]}" -ne 1 ]; then
            echo "Use --provider all by itself." >&2
            exit 2
        fi
        selected=(codex claude-code opencode)
        break
    fi
    if [[ ! "$provider" =~ ^(codex|claude-code|opencode)$ ]]; then
        echo "Unknown provider: $provider. Use --help for choices." >&2
        exit 2
    fi
    if [ -z "${seen[$provider]-}" ]; then
        selected+=("$provider")
        seen[$provider]=1
    fi
done

args=()
if [ "$force" -eq 1 ]; then
    args+=(--force)
fi
"$repo_root/prompts/link-skills.sh" "${args[@]}" "${selected[@]}"
printf 'Skills linked for: %s\n' "${selected[*]}"
