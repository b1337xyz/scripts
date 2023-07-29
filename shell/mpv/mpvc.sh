#!/usr/bin/env bash
set -e
declare -a args=()
for arg in "$@";do
    if [ -S "$arg" ];then socket=$arg ;else args+=("$arg"); fi
done

check_status() {
    echo '{"command":["get_property", "pid"]}' | socat - "$1" >/dev/null 2>&1
}

if [ -z "$socket" ];then
    while read -r socket;do
        check_status "$socket" && break
    done < <(find /tmp -type s -name 'mpv*' 2>/dev/null)
else
    check_status "$socket" || {
        echo "ERROR: Connection failed with '$socket'"; exit 1;
    }
fi
echo "socket: ${socket}"

case "${args[0]}" in
    lsp)      cmd='"get_property", "property-list"' ;;
    lsc)      cmd='"get_property", "command-list"'  ;;
    toggle)   cmd='"cycle", "pause"'        ;;
    prev)     cmd='"playlist-prev"'         ;;
    next)     cmd='"playlist-next"'         ;;
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
    status)     cmd='"script-binding", "stats/display-stats"' ;;
    vol)      cmd=$(printf '"set", "volume", "%s"' "${args[1]}") ;;
    load)     cmd=$(printf '"loadfile", "%s"' "${args[1]}") ;;
    *)  echo -e "Usage: ${0##*/} <command> <socket>"
        grep -oP '^[\t ]+\w+\).*(?= ;;)' "$0"; exit 0 ;;
esac

echo '{"command": ['"${cmd}"']}' | socat - "$socket" >&2
