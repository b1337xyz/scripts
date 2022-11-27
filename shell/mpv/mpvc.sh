#!/usr/bin/env bash

while [ $1 ];do
    case "$1" in
        -s)
            shift
            [ -S "$1" ] || { echo "$1: not a socket"; exit 1; }
            sockect="$1"
        ;;
        *)  arg="$1" ;;
    esac
    shift
done
sockect=${sockect:-/tmp/mpvsocket}
echo "$sockect"

check_status() {
    echo '{"command":["get_property", "pid"]}' | socat - "$1"
}

check_status "$sockect" || exit 1

case "$arg" in
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
    nextc)    cmd='"add", "chapter", "1"'   ;;
    prevc)    cmd='"add", "chapter", "-1"'  ;;
    show)     cmd='"script-binding", "stats/display-stats"' ;;
    *) echo "${0##*/} [-s <SOCKET>] [toggle next prev forward backward mute up down fs loop]"; exit 1 ;;
esac

echo '{"command": ['"${cmd}"']}' | socat - "$sockect"
