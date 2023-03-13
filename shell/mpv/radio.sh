#!/bin/sh

set -eo pipefail

FIFO=/tmp/mpvradio
src=$(dirname "$(realpath "$0")")
conf="${src}/radio.txt"
url=$(
    cut -d'|' -f1 "$conf"   |
    dmenu -l 20 -i -c       |
    xargs -rI{} grep -F "{}" "$conf" |
    cut -d'|' -f2
)
[ -z "$url" ] && exit 1
if [ -S "$FIFO" ] && pgrep -f -- '--profile=radio' >/dev/null 2>&1
then
    echo '{"command": ["loadfile", "'"$url"'"]}' | socat - "$FIFO"
fi
