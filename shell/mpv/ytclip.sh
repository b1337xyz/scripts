#!/usr/bin/env bash

url=$(xclip -sel clip -o)
if echo "$url" | grep -q 'youtube.com/';then
    notify-send "Playing now ♪" "$url"
    mpv --profile=ytclip "$url"
fi
