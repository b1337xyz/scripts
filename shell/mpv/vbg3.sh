#!/usr/bin/env bash
# https://github.com/CalinLeafshade/dots/blob/master/bin/bin/bg.sh

set -eo pipefail

command -v xwinwrap &>/dev/null || { echo 'install xwinwrap'; exit 1; }

if pgrep -x xwinwrap &>/dev/null;then
    pkill -15 xwinwrap || { echo 'failed to kill xwinwrap'; exit 1; }
    [ -f "$1" ] && sleep 0.5
fi

main() {
    xwinwrap -ov -ni -g "$1" -- mpv -wid WID \
        --no-config --no-audio --no-osc --no-osd-bar \
        --loop-file                 \
        --really-quiet              \
        --fullscreen                \
        --no-stop-screensaver       \
        --vo=gpu --hwdec=vaapi      \
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
        "$2" &>/dev/null &
}

if [ -f "$1" ];then
    # xrandr -q | grep -iF "HDMI1 connected"
    while read -r i;do
        main "$i" "$1"
    done < <(xrandr -q | grep ' connected' | grep -oP '\d+x\d+\+\d+\+\d+')
fi
