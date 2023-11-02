#!/bin/sh
find ~/.cache/aria2 -ctime +1 -delete

session=${HOME}/.cache/aria2/session
script=${HOME}/.scripts/python/a2notify.py
[ -f "$session" ] || :>"$session"
aria2c  -D --enable-rpc --continue \
    --input-file="$session" \
    --on-bt-download-complete="${script}" \
    --on-download-complete="${script}" \
    --on-download-error="${script}" \
    --on-download-start="${script}" \
    --save-session="$session" \
    --save-session-interval=60 \
    --log "${HOME}/.cache/aria2/aria2.$(date +%Y%m%d).log"
