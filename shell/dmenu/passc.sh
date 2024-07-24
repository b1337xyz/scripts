#!/usr/bin/env bash
set -eo pipefail

if [ -n "$DISPLAY" ];then
    # passmenu -l 15 -c
    find "$PASSWORD_STORE_DIR" -name '*.gpg' -printf '%P\n' | 
        sed 's/\.gpg$//g' | dmenu -c -l 15 | xargs -r pass show -c
else
    find "$PASSWORD_STORE_DIR" -name '*.gpg' -printf '%P\n' |
        sed 's/\.gpg$//g' | fzf --height 15 | xargs -ro pass ls
fi

