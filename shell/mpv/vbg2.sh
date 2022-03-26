#!/bin/bash
# https://github.com/CalinLeafshade/dots/blob/master/bin/bin/bg.sh

command -v xwinwrap &>/dev/null || exit 1

PIDFILE="/var/run/user/$UID/bg.pid"

declare -a PIDs

_screen() {
    scr="$1"
    shift
    xwinwrap -ov -ni -g "$scr" -- mpv --fullscreen\
        --no-stop-screensaver \
        --vo=vdpau --hwdec=vdpau \
        --loop-file --no-audio --no-osc --no-osd-bar -wid WID \
        --no-input-default-bindings \
        --keepaspect=no \
        "$@" &
    PIDs+=($!)
}

while read -r p; do
  [[ $(ps -p "$p" -o comm=) == "xwinwrap" ]] && kill -9 "$p";
done < $PIDFILE 2>/dev/null

sleep 0.5

for i in $( xrandr -q | grep ' connected' | grep -oP '\d+x\d+\+\d+\+\d+')
do
    _screen "$i" "$@"
done

printf "%s\n" "${PIDs[@]}" > $PIDFILE
