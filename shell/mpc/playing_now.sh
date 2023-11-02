#!/usr/bin/env bash
CACHE=~/.cache/thumbnails/mpc
MPD_CONF=~/.config/mpd/mpd.conf

get_info() {
    mpc -f 'file %file%\n[title %title%\n][album %album%\n][artist %artist%\n]time %time%' | head -n -2
}

while read -r i;do
    v=${i#* }
    case "$i" in
        file*)   file=$v  ;;
        title*)  title=$v ;;
        artist*) artist="Artist: $v\n" ;;
        album*)  album="Album: $v\n"   ;;
        time*)   time="Duration: $v\n" ;;
    esac
done < <(get_info)

music_dir=$(sed -n 's/music_directory[^"]*.\(.*\)"$/\1/p' "$MPD_CONF")
music_dir=${music_dir/\~/${HOME}}
path=${music_dir}/${file}
filename=${path##*/}
title=${title:-$filename}
image=${CACHE}${path}.jpg
mkdir -p "${image%/*}"

[ -f "$image" ] || ffmpeg -nostdin -v -8 -i "$path" "$image"
notify-send -r 10 -i "$image" "♫ Playing now..." "${title}\n${album}${artist}${time}"
# pkill -SIGRTMIN+21 i3blocks

# conky_pid=$(pgrep -f 'conky.*conky.mpd.conf')
# if [ -n "$conky_pid" ];then
#     kill -SIGUSR1 "$conky_pid"
# fi
