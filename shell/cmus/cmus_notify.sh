#!/usr/bin/env bash
COVER=~/.cache/thumbnails/albums
DEFAULT_ICON=media-optical-audio

[ -d "$COVER" ] || mkdir -p "$COVER"

while [ -n "$1" ];do
    case "$1" in
        status)   shift; [ "$1" = playing ] || exit 0; status=${1^} ;;
        file)     shift; file=$1 ;;
        artist)   shift; artist=$1 ;;
        album)    shift; album=$1 ;;
        title)    shift; title=$1 ;;
        date)     shift; date=$1 ;;
        duration) shift; duration=$(printf '%02d:%02d' $(($1/60)) $(($1%60))) ;;
    esac
    shift
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
