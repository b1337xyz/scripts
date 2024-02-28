#!/bin/sh

set -eo pipefail

# > ~/.config/mpv/mpv.conf
# [radio]
# input-ipc-server=/tmp/mpvradio
# really-quiet=yes
# idle=yes
# save-position-on-quit=no
# no-resume-playback
# no-video

SOCK=/tmp/mpvradio
src=$(realpath "$0")
conf=${src%/*}/radio.txt
url=$(cut -d'|' -f1 "$conf" | fzf | grep -Ff - "$conf" | cut -d'|' -f2)
if [ -S "$SOCK" ] && [ -n "$url" ]
then
    printf '{"command": ["loadfile", "%s"]}\n' "$url" | socat - "$SOCK"
else
    exec mpv --profile=radio "$url" >/dev/null 2>&1 &
fi
