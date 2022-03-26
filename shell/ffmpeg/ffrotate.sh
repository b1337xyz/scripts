#!/bin/sh

r=0
while [ $#  -gt 0 ];do
    case "$1" in
        [0-3]) r=$1 ;;
        *) [ -f "$1" ] && vid=$1 ;;
    esac
    shift
done

# 0 - Rotate by 90 degrees counter-clockwise and flip vertically. This is the default.
# 1 - Rotate by 90 degrees clockwise.
# 2 - Rotate by 90 degrees counter-clockwise.
# 3 - Rotate by 90 degrees clockwise and flip vertically.

out=new_${vid##*/}
if ! ffmpeg -hide_banner -i "$vid" -map 0:v -c:v libx264 \
    -vf "transpose=${r},scale='min(1280,iw)':'min(720,ih):force_original_aspect_ratio=decrease'" \
    -crf 27 -preset ultrafast -tune zerolatency "$out"
then
    rm "$out"
    exit 1
fi

