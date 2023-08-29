#!/usr/bin/env bash
set -eo pipefail

if [ -n "$DISPLAY" ];then
    grep -q 'pinentry-gtk' ~/.config/gnupg/gpg-agent.conf || {
        notify-send 'Not using pinentry-gtk';
        exit 1;
    }
    passmenu -l 15 -c
else
    find "$PASSWORD_STORE_DIR" -name '*.gpg' -printf '%P\n' |
        sed 's/\.gpg$//g' | fzf --height 15 | xargs -ro pass ls
fi

notify-send "Password copied to clipboard"
