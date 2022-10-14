#!/bin/sh
set -e
session=~/.cache/aria2/session
pkill -e -f -- 'aria2c -D -V --enable-rpc'
sleep 5
aria2c -D -V --enable-rpc --input-file "$session"
