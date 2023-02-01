#!/bin/sh
pkill -15 -e -f -- 'aria2c -D -V --enable-rpc' && sleep 1

session="${HOME}"/.cache/aria2/session
script="${HOME}"/.local/bin/aria2notify.py
set -- -D -V --enable-rpc \
    --on-bt-download-complete="${script}" \
    --on-download-complete="${script}" \
    --on-download-error="${script}" \
    --on-download-start="${script}" \
    --save-session-interval=30

if [ -f "$session" ];then
    aria2c "$@" --input-file="$session"
else
    aria2c "$@" --save-session="$session"
fi
