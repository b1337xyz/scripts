#!/usr/bin/env bash
# https://github.com/CalinLeafshade/dots/blob/master/bin/bin/bg.sh

command -v xwinwrap &>/dev/null || exit 1

PIDFILE="/var/run/user/$UID/bg.pid"

declare -a PIDs

_screen() {
    xwinwrap -ov -ni -g "$1" -- mpv --no-config \
        --fullscreen                \
        --no-stop-screensaver       \
        --vo=gpu --hwdec=vaapi      \
        --loop-file --no-audio --no-osc --no-osd-bar -wid WID \
        --no-input-default-bindings \
        --keepaspect=no             \
        --scale=bilinear            \
        --cscale=bilinear           \
        --dscale=bilinear           \
        --scale-antiring=0          \
        --cscale-antiring=0         \
        --dither-depth=no           \
        --correct-downscaling=no    \
        --sigmoid-upscaling=no      \
        --deband=no                 \
        --vd-lavc-fast              \
        "$2" >/dev/null 2>&1 &
    PIDs+=($!)
}

if [ -s "$PIDFILE" ];then
    while read -r p; do
      [[ $(ps -p "$p" -o comm=) == "xwinwrap" ]] && kill -9 "$p";
    done < $PIDFILE 2>/dev/null
fi

while [ $# -gt 0 ];do
    case "$1" in
        -s)
            shift
            scr=$1
            xrandr -q | grep -qiF "${1} connected" || exit 1
        ;;
        *) 
            [ -f "$1" ] && input=$1
        ;;
    esac
    shift
done

if [ -f "$input" ];then
    sleep 0.5
    tmpfile=$(mktemp)
    if [ -n "$scr" ];then
        xrandr -q | grep -iF "${scr} connected"
    else
        xrandr -q | grep ' connected'
    fi | grep -oP '\d+x\d+\+\d+\+\d+' >> "$tmpfile"

    while read -r i;do
        _screen "$i" "$input"
    done < "$tmpfile"
    printf "%s\n" "${PIDs[@]}" > $PIDFILE
    rm "$tmpfile"
fi
