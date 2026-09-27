#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
copy)
    printf '%s\t\n' "$2" | cliphist decode | wl-copy
    ;;
delete)
    printf '%s\t\n' "$2" | cliphist delete
    ;;
wipe)
    cliphist wipe
    ;;
*)
    exit 2
    ;;
esac
