#!/usr/bin/env bash
COVER=~/.cache/thumbnails/albums
DEFAULT_ICON=media-optical-audio

[ -d "$COVER" ] || mkdir -p "$COVER"

while [ -n "$1" ];do
    k=$1 v=$1
    shift 2
    case "$k" in
        status) [ "$v" = playing ] || exit 0; status=${v^} ;;
        file) file=$v ;;
        artist) artist=$v ;;
        album) album=$v ;;
        title) title=$v ;;
        date) date=$v ;;
        duration) duration=$(printf '%02d:%02d' $((v / 60)) $((v % 60))) ;;
    esac
done

filename=${file##*/} filename=${filename%.*}
title=${title:-$filename}
img=$(md5sum "$file" | awk '{print $1".jpg"}')
img="${COVER}/${img}"
[ -f "$img" ] || ffmpeg -v -8 -i "$file" "$img"
[ -f "$img" ] || img="$DEFAULT_ICON"
msg=
for i in "$title" "$artist" "$album" "$date" "$duration";do
    [ -n "$i" ] && msg="${msg}${i}\n"
done

dunstify -r 1337 -i "$img" "♪ ${status}" "$msg"

echo -n "$title $album $artist" | sed 's/ \+$//' > /tmp/.cmus-status
# pkill -SIGRTMIN+20 i3blocks
