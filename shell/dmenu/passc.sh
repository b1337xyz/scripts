#!/usr/bin/env bash
set -eo pipefail

if [ -n "$DISPLAY" ];then
    passmenu -l 15 -c
    notify-send "Password copied to clipboard"
else
    find "$PASSWORD_STORE_DIR" -name '*.gpg' -printf '%P\n' |
        sed 's/\.gpg$//g' | fzf --height 15 | xargs -ro pass ls
fi

