#!/usr/bin/env bash
set -x
# Get mpvpaper here -> https://github.com/GhostNaN/mpvpaper
[ -f "$1" ] || exit 1

mpv_options=(
    --no-config \
    --no-audio \
    --no-osc \
    --no-osd-bar \
    --really-quiet \
    --loop-file \
    --fullscreen \
    --no-stop-screensaver \
    --hwdec=vaapi \
    --no-input-default-bindings \
    --keepaspect=no \
    --scale=bilinear \
    --cscale=bilinear \
    --dscale=bilinear \
    --scale-antiring=0 \
    --cscale-antiring=0 \
    --dither-depth=no \
    --correct-downscaling=no \
    --sigmoid-upscaling=no \
    --deband=no
)

pid=$(pgrep -x swaybg)
if [ -n "$pid" ];then
    readarray -d $'\0' swaybg_cmd </proc/"${pid}"/cmdline
    trap '"${swaybg_cmd[@]}" >/dev/null 2>&1 &' EXIT
    kill "$pid"
fi
mpvpaper -o "${mpv_options[*]}" '*' "$1" >/dev/null 2>&1
