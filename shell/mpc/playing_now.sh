#!/usr/bin/env bash

COVER=~/.cache/thumbnails/albums

main() {
    IFS='|' read -r fpath artist album title duration < <(
        mpc -f '%file%#|%artist%#|%album%#|%title%#|%time%' | head -1)
    fpath=~/Music/"$fpath"
    fname=${fpath##*/}
    title=${title:-$fname}
    img=$(md5sum "$fpath" | awk '{print $1".jpg"}')
    img=${COVER}/${img}
    [ -f "$img" ] || ffmpeg -hide_banner -v -8 -i "$fpath" "$img"
    notify-send -i "$img" "♫ Playing now..." "$title\n$album\n$artist\n$duration"
}
main 2>/dev/null
