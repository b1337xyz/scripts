#!/usr/bin/env bash
# set -x
declare -a args=()
for arg in "$@";do
    if [ -S "$arg" ];then sockect=$arg ;else args+=("$arg"); fi
done
sockect=${sockect:-/tmp/mpvsocket}

check_status() {
    echo '{"command":["get_property", "pid"]}' | socat - "$1"
}
check_status "$sockect" || exit 1

case "${args[0]}" in
    lsp)      cmd='"get_property", "property-list"' ;;
    lsc)      cmd='"get_property", "command-list"' ;;
    toggle)   cmd='"cycle", "pause"'        ;;
    next)     cmd='"playlist-next"'         ;;
    prev)     cmd='"playlist-prev"'         ;;
    replay)   cmd='"seek", "0", "absolute"' ;;
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
    load)     cmd=$(printf '"loadfile", "%s"' "${args[1]}") ;;
    *) echo "${0##*/} [toggle next prev forward backward mute up down fs loop load] <SOCKET>"; exit 1 ;;
esac

echo '{"command": ['"${cmd}"']}' | socat - "$sockect"
