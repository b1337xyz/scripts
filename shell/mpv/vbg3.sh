#!/usr/bin/env bash
# https://github.com/CalinLeafshade/dots/blob/master/bin/bin/bg.sh

pkill -x xwinwrap >/dev/null 2>&1

main() {
    echo "$@"
    xwinwrap -ov -ni -g "$1" -- mpv --wid=%WID \
        --no-config --no-audio --no-osc --no-osd-bar \
        --really-quiet \
        --loop-file                 \
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
        "$2" >/dev/null 2>&1 &
}

if [ -f "$1" ];then
    sleep 1
    while read -r i;do
        main "$i" "$1"
    done < <(xrandr -q | grep ' connected' | grep -oP '\d+x\d+\+\d+\+\d+')
fi
