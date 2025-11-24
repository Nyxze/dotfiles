#!/usr/bin/env bash
work_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )
filter=()
dry="0"


log(){
    if [[ $dry == "1" ]]; then
        echo "[DRY RUN] : $@"
    else
        echo "$@"
    fi
}

run(){
    log "Running $@"
    if [[ $dry == "1" ]]; then
        return
    fi
    "$@"
}

# Parse --dry args
while [[ $# -gt 0 ]]; do
    if [[ $1 == "--dry" ]]; then
        dry="1"
    else
        filter+=("$1")
    fi
    shift
done


cd $work_dir

# Change to -executable for unix instead of extension based filtering
scripts=($(find ./scripts -maxdepth 1 -mindepth 1 -type f -name "*.sh"))
script_count=${#scripts[@]}

log "$script_count scripts found"

for script in "${scripts[@]}"; do
    base_name=$(basename "$script")
    should_run=1
    if [[ ${#filter[@]} -gt 0 ]]; then
        for f in "${filter[@]}"; do
            if [[ "$script" == *"$f"* ]]; then
                should_run=0
                break
            fi
        done
    fi

    if [[ $should_run -eq 1 ]]; then
        run ./"$script"
    else
        log "Skipping $script"
    fi
done