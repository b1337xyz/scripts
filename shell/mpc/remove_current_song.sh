#!/usr/bin/env bash
MPD_CONF=~/.config/mpd/mpd.conf
music_dir=$(sed -n 's/music_directory[^"]*.\(.*\)"$/\1/p' "$MPD_CONF")
music_dir=${music_dir/\~/${HOME}}
song=${music_dir}/$(mpc -f '%file%' | head -1)
if [ -f "$song" ];then
    ask=$(printf 'No\nYes' | dmenu -l 2 -i -p "remove '${song}'?")
    if [ "$ask" = "Yes" ];then
        rm -v "$song" | tr \\n \\0 | xargs -0r notify-send -i user-trash
        mpc -q next 
    fi
fi
