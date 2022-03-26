#!/usr/bin/env bash

if [ -z "$1" ];then
    video=$(xclip -sel clip -o 2>/dev/null) 
    [ -z "$video" ] && exit 1
else
    video="$1"
fi
case "$video" in
    https://www.youtube.com/*)
        lock=/tmp/.videos_dGVtcG9yYXJ5
        [ -f "$lock" ] && notify-send "$(date) video added to queue" "$video"
        while [ -f "$lock" ];do sleep 15 ;done

        notify-send "$(date)" "$video"
        touch "$lock"
        trap 'rm -f $lock; exit 0' SIGHUP SIGINT SIGQUIT SIGTERM EXIT
        mpv --really-quiet "$video"
    ;;
    *) notify-send "Invalid url: \"$video\"" ; exit 1 ;;
esac
