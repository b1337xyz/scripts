#!/usr/bin/env bash
# https://github.com/CalinLeafshade/dots/blob/master/bin/bin/bg.sh

pkill -x xwinwrap >/dev/null 2>&1

main() {
    xwinwrap -ov -ni -sub 10 -g "$1" -- mpv -wid=10 \
        --no-config --no-audio --no-osc --no-osd-bar \
        --loop-file                 \
        --fullscreen                \
        --really-quiet              \
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
        "$2" >/dev/null 2>&1 &
}

if [ -f "$1" ];then
    sleep 1
    while read -r i;do
        main "$i" "$1"
    done < <(xrandr -q | grep ' connected' | grep -oP '\d+x\d+\+\d+\+\d+')
fi
