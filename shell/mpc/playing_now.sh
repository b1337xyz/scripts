#!/usr/bin/env bash
set -e

CACHE=~/.cache/thumbnails/mpc
MPD_CONF=~/.config/mpd/mpd.conf

get_info() {
    mpc -f 'file %file%\n[title %title%\n][album %album%\n][artist %artist%\n]time %time%' | head -n -2
}

while read -r i;do
    o=${i#* }
    case "$i" in
        file*)   file=$o  ;;
        title*)  title=$o ;;
        artist*) artist="Artist: $o\n" ;;
        album*)  album="Album: $o\n"   ;;
        time*)   time="Duration: $o\n" ;;
    esac
done < <(get_info)

music_dir=$(sed -n 's/music_directory[^"]*.\(.*\)"$/\1/p' "$MPD_CONF")
music_dir=${music_dir/\~/${HOME}}
path=${music_dir}/${file}
filename=${path##*/}
title=${title:-$filename}
image=${CACHE}${path}.jpg
mkdir -p "${image%/*}"

[ -f "$image" ] || ffmpeg -nostdin -v -8 -i "$path" "$image" || true
notify-send -r 10 -i "$image" "♫ Playing now..." "${title}\n${album}${artist}${time}"
pkill -SIGRTMIN+21 i3blocks
