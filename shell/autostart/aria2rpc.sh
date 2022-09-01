#!/usr/bin/env bash

session=~/.cache/aria2/session
if [ -f "$session" ];then
    tmux new-session -d aria2c -V --enable-rpc --input-file "$session"
else
    tmux new-session -d aria2c -V --enable-rpc
fi
