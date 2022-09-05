#!/bin/sh

set -e

session=~/.cache/aria2/session

pgrep aria2c | xargs -r kill
aria2c -D --enable-rpc --input-file "$session"
sleep 3
pgrep -f 'python3.*aria2bt/watch.py' | xargs -r kill
python3 ~/.scripts/python/aria2bt/watch.py &
