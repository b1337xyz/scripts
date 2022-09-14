#!/bin/sh

command -v dmenu >/dev/null 2>&1 ||
    { echo 'install dmenu'; exit 1; }
command -v mpv >/dev/null 2>&1 ||
    { echo 'install mpv'; exit 1; }

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
if [ -S "$FIFO" ] && pgrep -f -- '--profile=radio';then
    echo '{"command": ["loadfile", "'"$url"'"]}' | socat - "$FIFO"
else
    tmux new-session -s radio -d mpv --profile=radio "$url"
fi
