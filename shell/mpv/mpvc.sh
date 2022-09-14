#!/usr/bin/env bash

SOCKET=/tmp/mpvradio
case "$1" in
    toggle)     comm='"cycle", "pause"'         ;;
    next)       comm='"playlist-next"'          ;;
    prev)       comm='"playlist-prev"'          ;;
    forward)    comm='"seek", "50"'             ;;
    backward)   comm='"seek", "-50"'            ;;
    mute)       comm='"cycle", "mute"'          ;;
    up)         comm='"add", "volume", "10"'    ;;
    down)       comm='"add", "volume", "-10"'   ;;
    fs)         comm='"cycle", "fullscreen"'    ;;
esac

[ -n "$comm" ] &&
    echo '{"command": ['"${comm}"']}' | socat - "$SOCKET"
