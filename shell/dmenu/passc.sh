#!/usr/bin/env bash
set -eo pipefail

find "$PASSWORD_STORE_DIR" -name '*.gpg' -printf '%P\n' |
    sed 's/\.gpg$//g' | dmenu -l 15 -c | xargs -r pass show -c

notify-send "Password copied to clipboard"
