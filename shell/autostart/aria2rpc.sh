#!/bin/sh
session=~/.cache/aria2/session

pgrep aria2c | xargs -r kill
sleep 1
aria2c -D -V --enable-rpc --input-file "$session"
