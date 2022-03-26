#!/usr/bin/env bash

get_volume() {
    pactl list sinks | sed 's/\s*//;s/%//g' | grep ^Volume | awk '{print $5}'
}

case "$1" in
    up) pactl set-sink-volume @DEFAULT_SINK@ +5% ;;
    down) pactl set-sink-volume @DEFAULT_SINK@ -5% ;;
    toggle) pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
    [0-9]*) pactl set-sink-volume @DEFAULT_SINK@ "$1"% ;;
esac && pkill -SIGRTMIN+10 i3blocks

exit 0
