#!/usr/bin/env bash
COVER=~/.cache/thumbnails/albums
DEFAULT_ICON=/usr/share/icons/Chicago95/devices/32/media-optical-audio.png
get_info() {
    cmus-remote -Q | awk '{
    if ( $0 ~ /^(file|duration|status)/) {
        if ( $1 ~ /duration/ ) {
            printf("duration %02d:%02d\n", $2 / 60, $2 % 60)
        } else {
            print $0
        }
    } else if ( $0 ~ /^tag (artist|album|title|date) /) {
        sub(/^tag /, "", $0)
        print $0
    }}'
}

last_played=
while :;do
    while read -r i;do
        case "$i" in
            status*)    _status="${i#* }"   ;;
            file*)      file="${i#* }"      ;;
            title*)     title="${i#* }"     ;;
            duration*)  duration="Duration: ${i#* }"  ;;
            artist*)    artist="Artist: ${i#* }" ;;
            album*)     album="Album: ${i#* }"   ;;
            date*)      date="${i#* }"      ;;
        esac
    done < <(get_info)
    [ "$_status" != "playing" ] && { sleep 15; continue; }
    [ "$title" == "$last_played" ] && { sleep 15; continue; }
    last_played="$title"
    fname=${file##*/}
    title=${title:-$fname}
    [ -n "$date" ] && title="${title} ($date)"
    img=$(md5sum "$file" | awk '{print $1".jpg"}')
    img="${COVER}/${img}"
    [ -f "$img" ] || ffmpeg -v -8 -i "$file" "$img"
    [ -f "$img" ] || img="$DEFAULT_ICON"
    notify-send -i "$img" \
        "[cmus] ♫ Playing now..." "$title\n$artist\n$album\n$duration"
done
