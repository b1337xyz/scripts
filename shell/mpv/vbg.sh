#!/usr/bin/env bash

pkill -x xwinwrap >/dev/null 2>&1

main() {
    xwinwrap -ov -ni -g "$1" -- mpv --wid=%WID \
        --no-config --no-audio --no-osc --no-osd-bar \
        --really-quiet \
        --loop-file                 \
        --fullscreen                \
        --no-stop-screensaver       \
        --vo=gpu --hwdec=vaapi      \
        --no-input-default-bindings \
        --keepaspect=yes \
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
    while read -r i;do
        main "$i" "$1"
    done < <(xrandr -q | grep ' connected' | grep -oP '\d+x\d+\+\d+\+\d+' | fzf -m)
fi

exit 0
