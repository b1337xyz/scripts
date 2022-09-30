#!/usr/bin/env bash

SOCKET=/tmp/mpvradio
case "$1" in
    toggle)   cmd='"cycle", "pause"'        ;;
    next)     cmd='"playlist-next"'         ;;
    prev)     cmd='"playlist-prev"'         ;;
    forward)  cmd='"seek", "50"'            ;;
    backward) cmd='"seek", "-50"'           ;;
    mute)     cmd='"cycle", "mute"'         ;;
    up)       cmd='"add", "volume", "10"'   ;;
    down)     cmd='"add", "volume", "-10"'  ;;
    fs)       cmd='"cycle", "fullscreen"'   ;;
    loop)     cmd='"cycle", "loop-file"'    ;;
esac

[ -n "$cmd" ] &&
    echo '{"command": ['"${cmd}"']}' | socat - "$SOCKET"
