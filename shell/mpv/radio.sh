#!/bin/sh

set -eo pipefail

SOCK=/tmp/mpvradio
src=$(realpath "$0")
conf=${src%/*}/radio.txt
url=$(
    cut -d'|' -f1 "$conf"   |
    dmenu -l 20 -i -c       |
    xargs -rI{} grep -F "{}" "$conf" |
    cut -d'|' -f2
)
if [ -S "$SOCK" ] && [ -n "$url" ]
then
    printf '{"command": ["loadfile", "%s"]}\n' "$url" | socat - "$SOCK"
else
    exec mpv --profile=radio "$url"
fi
