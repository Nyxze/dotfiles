#!/usr/bin/env bash

lua_quote() {
    printf '%s' "$1" | od -An -tu1 | awk '
        BEGIN { printf "\"" }
        { for (i = 1; i <= NF; i++) printf "\\%03d", $i }
        END { printf "\"" }
    '
}

hypr_lua() {
    local result
    result=$(hyprctl "$1" "$2") || return
    if [ "$result" != ok ]; then
        printf '%s\n' "$result" >&2
        return 1
    fi
}
