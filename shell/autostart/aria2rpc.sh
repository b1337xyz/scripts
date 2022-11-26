#!/bin/sh
pkill -e -f -- 'aria2c -D -V --enable-rpc' && sleep 5

session="${HOME}"/.cache/aria2/session
if [ -f "$session" ];then
    aria2c -D -V --enable-rpc --input-file="$session"
else
    aria2c -D -V --enable-rpc --save-session="$session"
fi

# session="${HOME}"/.cache/aria2/prowlarr.session
# config="${HOME}"/.config/aria2/prowlarr.conf
# if [ -f "$session" ];then
#     aria2c -D -V --enable-rpc --conf-path="$config" --input-file="$session"
# else
#     aria2c -D -V --enable-rpc --conf-path="$config" --save-session="$session"
# fi
