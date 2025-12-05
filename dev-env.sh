#!/usr/bin/env bash
work_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )
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
    fi
    shift
done

copy_dir(){
    from=$1
    to=$2

    pushd $from > /dev/null

    dirs=$(find . -maxdepth 1 -mindepth 1 -type d)
    for dir in $dirs; do
        #Clear dest before copying
    run rm -rf $to/$dir
        run cp -r $dir $to/$dir
    done
    popd > /dev/null
}

copy_file(){
    file=$1
    to=$2
    name=$(basename $file)
    if [ -e $to/$name ]; then
        run rm $to/$name
    fi
    run cp $file $to/$name
}
cd $work_dir

log '------ DEV ENVIRONMENT SETUP ------'


# Configs
copy_dir .config $XDG_CONFIG_HOME
copy_dir .local $HOME/.local


# Scripts 
copy_file .zshrc  $HOME/.zshrc
copy_file .zsh_profile $HOME/.zsh_profile

