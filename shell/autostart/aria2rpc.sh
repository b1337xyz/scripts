#!/bin/sh

set -e

session=~/.cache/aria2/session

pgrep aria2c | xargs -r kill
sleep 1
aria2c -D -V --enable-rpc --input-file "$session"

# pgrep -f 'python3.*aria2bt/watch.py' | xargs -r kill
# python3 ~/.scripts/python/aria2bt/watch.py &
