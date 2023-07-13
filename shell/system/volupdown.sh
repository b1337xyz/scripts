#!/usr/bin/env bash
exec 2>/dev/null

case "$1" in
    up)     pactl set-sink-volume @DEFAULT_SINK@ +5%    ;;
    down)   pactl set-sink-volume @DEFAULT_SINK@ -5%    ;;
    toggle) pactl set-sink-mute @DEFAULT_SINK@ toggle   ;;
    [0-9]*) pactl set-sink-volume @DEFAULT_SINK@ "$1"%  ;;
esac

volume=$(pactl get-sink-volume @DEFAULT_SINK@ | awk '/Volume:/{print substr($5, 1, length($5)-1)}')
if pactl list sinks | grep -q 'Mute: yes' ;then
    dunstify -r 1337 -i audio-volume-muted -h "int:value:$volume" "Volume" 
else
    dunstify -r 1337 -i audio-volume-high -h "int:value:$volume" "Volume" 
fi

# pkill -SIGRTMIN+10 i3blocks

exit 0
