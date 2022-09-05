#!/usr/bin/env bash
pgrep -x ffmpeg && pkill -15 -x ffmpeg

parse_display() {
    sed 's/\([0-9]*\)x\([0-9]*\)\(.[0-9]*\)\(.[0-9]*\)/\1 \2 \3 \4/'
}
get_scr() {
    regex="(\w*) connected.* ([0-9]*x[0-9]*\+[0-9]*\+[0-9]*)"
    xrandr -q | while read -r i;do
        if [[ "$i" =~ $regex ]];then
            a="${BASH_REMATCH[1]}"
            b="${BASH_REMATCH[2]}"
            echo -n "$a "
            echo "$b" | parse_display
        fi
    done
    # xrandr -q | grep ' connected' | grep -oP '\d*x\d*\+\d*\+\d*' | tr 'x+' ' '
}

if [ "$1" = "-x" ];then
    read w h x y < <(xwininfo | grep -oP '(?<= -geometry ).*' | parse_display)
elif [ "$1" = "-s" ];then
    read w h x y < <(slop -o | parse_display)
else
    read _ w h x y < <(get_scr | fzf)
fi

[ -z "$w" ] && exit
w=$(( w - ( w % 2 ) ))
h=$(( h - ( h % 2 ) )) 
echo ">>> ${w}x${h} $x $y"

out=~/record_$(date +%Y%m%d%H%M%S).mp4
ffmpeg -threads 0 -hide_banner -v 16 -stats -y     \
    -framerate 30 -f x11grab            \
    -video_size "${w}x${h}" -i ":0.0$x,$y"   \
    -f pulse -ac 2 -i default                \
    -c:v libx264 -crf 24 \
    -preset fast "$out" || rm -v "$out"

## VAAPI
# ffmpeg -hide_banner -v 16 -stats -y \
#     -vaapi_device /dev/dri/renderD128 \
#     -framerate 30 -f x11grab -video_size "${w}x$h" -i ":0.0$x,$y" \
#     -f pulse -ac 2 -i default              \
#     -vf 'format=nv12,hwupload' -c:v h264_vaapi -qp 24 "$out"

