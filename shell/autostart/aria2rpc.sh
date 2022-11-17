#!/bin/sh
session="${HOME}"/.cache/aria2/session
pkill -e -f -- 'aria2c -D -V --enable-rpc' && sleep 5
if [ -f "$session" ];then
    aria2c -D -V --enable-rpc --input-file="$session"
else
    aria2c -D -V --enable-rpc --save-session="$session"
fi
