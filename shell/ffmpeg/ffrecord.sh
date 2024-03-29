#!/usr/bin/env bash
pgrep -x ffmpeg | xargs -r kill

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

case "$1" in
    -x) read -r w h x y < <(xwininfo | grep -oP '(?<= -geometry ).*' | parse_display) ;;
    -s) read -r w h x y < <(slop -o | parse_display) ;;
    -a) w=0 h=0 x=+0 y=+0
        while read -r _ nw nh _ _;do 
            w=$((w+nw))
            h=$nh
        done < <(get_scr)
        ;;
    *) read -r _ w h x y < <(get_scr | fzf) ;;
esac

[ -z "$w" ] && exit
w=$(( w - ( w % 2 ) ))
h=$(( h - ( h % 2 ) )) 

# pactl list short sources
# -f pulse -ac 2 -i 3 \

out=~/record_$(date +%Y%m%d%H%M%S).mp4
ffmpeg -threads 0 -hide_banner -v 16 -stats -y \
    -framerate 30 -f x11grab \
    -video_size "${w}x${h}" -i ":0.0$x,$y" \
    -ss 1 -c:v libx264 -crf 1 \
    -profile baseline -pix_fmt yuv420p \
    -preset fast "$out" || rm -v "$out"

## VAAPI
# ffmpeg -hide_banner -v 16 -stats -y \
#     -vaapi_device /dev/dri/renderD128 \
#     -framerate 30 -f x11grab -video_size "${w}x$h" -i ":0.0$x,$y" \
#     -f pulse -ac 2 -i default              \
#     -vf 'format=nv12,hwupload' -c:v h264_vaapi -qp 24 "$out"

