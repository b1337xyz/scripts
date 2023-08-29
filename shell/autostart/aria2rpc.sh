#!/bin/sh
pkill -15 -e -f -- 'aria2c -D --enable-rpc' && sleep 1

session=${HOME}/.cache/aria2/session
script=${HOME}/.scripts/python/a2notify.py
set -- -D --enable-rpc --continue \
    --on-bt-download-complete="${script}" \
    --on-download-complete="${script}" \
    --on-download-error="${script}" \
    --on-download-start="${script}" \
    --save-session="$session" \
    --save-session-interval=60 \
    --log "${HOME}/.cache/aria2/aria2.log.$(date +%Y%m%d)"

[ -f "$session" ] || :>"$session"
aria2c "$@" --input-file="$session"
