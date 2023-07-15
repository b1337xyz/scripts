#!/usr/bin/env bash
set -eo pipefail

if [ "$DISPLAY" ];then
    find "$PASSWORD_STORE_DIR" -name '*.gpg' -printf '%P\n' |
        sed 's/\.gpg$//g' | dmenu -l 15 -c | xargs -r pass show -c
else
    find "$PASSWORD_STORE_DIR" -name '*.gpg' -printf '%P\n' |
        sed 's/\.gpg$//g' | fzf --height 15 | xargs -ro pass ls

fi

notify-send "Password copied to clipboard"
