#!/usr/bin/env bash
NID=$$
COVER=~/.cache/thumbnails/albums
DEFAULT_ICON=media-optical-audio

[ -d "$COVER" ] || mkdir -vp "$COVER"

get_info() {
    cmus-remote -Q 2>/dev/null | awk '{
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
    fname=${file##*/}
    title=${title:-$fname}
    [ "$_status" != "playing" ] && { sleep 15; continue; }
    [ "$title" == "$last_played" ] && { sleep 5; continue; }
    last_played="$title"
    [ -n "$date" ] && title="${title} ($date)"
    img=$(md5sum "$file" | awk '{print $1".jpg"}')
    img="${COVER}/${img}"
    [ -f "$img" ] || ffmpeg -v -8 -i "$file" "$img"
    [ -f "$img" ] || img="$DEFAULT_ICON"
    dunstify -r "$NID" -i "$img" \
        "[cmus] ♫ Playing now..." "$title\n$artist\n$album\n$duration"
done
