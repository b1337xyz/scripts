#!/bin/sh
pkill -15 -e -f -- 'aria2c -D -V --enable-rpc' && sleep 1

session="${HOME}"/.cache/aria2/session
script="${HOME}"/.local/bin/a2notify.py
set -- -D -V --enable-rpc \
    --on-bt-download-complete="${script}" \
    --on-download-complete="${script}" \
    --on-download-error="${script}" \
    --on-download-start="${script}" \
    --save-session="$session" \
    --save-session-interval=30

if [ -s "$session" ];then
    aria2c "$@" --input-file="$session"
else
    aria2c "$@" 
fi

session=${session}.1
set -- -D -V --enable-rpc --rpc-listen-port 6801 \
    --continue \
    --save-session="$session" \
    --save-session-interval=30 \
    --max-connection-per-server=1 \
    --max-concurrent-downloads=1 \
    --auto-file-renaming=false \
    --force-save=false

if [ -s "$session" ];then
    aria2c "$@" --input-file="$session"
else
    aria2c "$@" 
fi
