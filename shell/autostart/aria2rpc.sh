#!/bin/sh
session=${HOME}/.cache/aria2/session
script=${HOME}/.scripts/python/a2cli/a2notify.py
[ -f "$session" ] || :>"$session"
aria2c  -D --enable-rpc --continue \
    --input-file="$session" \
    --on-bt-download-complete="${script}" \
    --on-download-complete="${script}" \
    --on-download-error="${script}" \
    --on-download-start="${script}" \
    --save-session="$session" \
    --save-session-interval=60
