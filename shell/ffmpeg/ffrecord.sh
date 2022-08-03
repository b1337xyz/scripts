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
    read w h x y < <(slop | parse_display)
else
    read _ w h x y < <(get_scr | fzf)
fi

[ -z "$w" ] && exit
w=$(( w - ( w % 2 ) ))
h=$(( h - ( h % 2 ) )) 
echo ">>> ${w}x${h} $x $y"

out=~/record_$(date +%Y%m%d%H%M%S).mp4
ffmpeg -hide_banner -v 16 -stats -y -f x11grab \
    -framerate 24 \
    -video_size "${w}x${h}" -i ":0.0$x,$y" \
    -f pulse -ac 2 -i default               \
    -c:v h264 "$out"
