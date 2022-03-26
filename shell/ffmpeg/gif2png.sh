#!/usr/bin/env bash

[ "${1##*.}" == "gif" ] || exit 1
ffmpeg -hide_banner -v 16 -i "$1" -vsync 0 "${1%.*}"_%05d.png
