#!/bin/sh

command -v dmenu >/dev/null 2>&1 ||
    { echo 'install dmenu'; exit 1; }
command -v mpv >/dev/null 2>&1 ||
    { echo 'install mpv'; exit 1; }

set -eo pipefail

src=$(dirname "$(realpath "$0")")
conf="${src}/radio.txt"
url=$(
    cut -d' ' -f1 "$conf"   |
    dmenu -l 10 -i -c       |
    xargs -rI{} grep -F "{}" "$conf" |
    cut -d'|' -f2
)
[ -z "$url" ] && exit 1
xterm -name floating_terminal   \
    -title radio                \
    -e "mpv --profile=radio \"$url\"" >/dev/null 2>&1
