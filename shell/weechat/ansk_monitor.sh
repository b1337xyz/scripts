#!/bin/sh
set -ex

FIFO=$(find /run/user/1000/weechat/ -type p)
cache=~/.cache/ansk

[ -z "$FIFO" ] && { echo "$FIFO not found"; exit 1; }

while pgrep -x weechat >/dev/null 2>&1;do
    curl -s "https://packs.ansktracker.net"     |
    grep -oP '/msg ANSK\|\w* xdcc send #\d*'    |
    while read -r msg;do
        if ! grep -qxF "$msg" "$cache" 2>/dev/null;then
            echo "*${msg}!" > "$FIFO"
            echo "$msg" | tee -a "$cache"
            sleep 5m
        fi
    done
    sleep 1h
done
