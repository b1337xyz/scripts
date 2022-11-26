#!/usr/bin/env bash
MUSIC_PATH=~/Music/$(mpc -f %file% | head -1)
if [ -a "$MUSIC_PATH" ] && [ $(printf 'y\nn' | dmenu -i -p "remove '${MUSIC_PATH::100}'?") = 'y' ];then
    rm -v "$MUSIC_PATH" | tr \\n \\0 | xargs -r0 notify-send
    mpc -q next 
fi
