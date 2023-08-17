#!/usr/bin/env bash
song=$(cmus-remote -Q | grep -oP '(?<=^file ).*' | head -1)
if [ -f "$song" ];then
    ask=$(printf 'Yes\nNo' | dmenu -l 2 -i -p "remove '${song::200}'?")
    if [ "$ask" = "Yes" ];then
        rm -v "$song" | tr \\n \\0 | xargs -0r notify-send -i user-trash
        cmus-remote -n 
    fi
fi
