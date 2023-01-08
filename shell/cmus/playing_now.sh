#!/usr/bin/env bash
set -eu

NID=$$
COVER=~/.cache/thumbnails/albums
DEFAULT_ICON=media-optical-audio
LOCK=/tmp/.cmus

[ -e "$LOCK" ] && exit 1
:>"$LOCK"
trap 'rm $LOCK' EXIT HUP INT

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
    unset title duration artist album date

    while read -r i;do
        case "$i" in
            status*)    _status="${i#* }"   ;;
            file*)      file="${i#* }"      ;;
            title*)     title="${i#* }"     ;;
            duration*)  duration="Duration: ${i#* }\n"  ;;
            artist*)    artist="Artist: ${i#* }\n" ;;
            album*)     album="Album: ${i#* }\n"   ;;
            date*)      date="${i#* }"      ;;
        esac
    done < <(get_info)

    [ "$_status" != "playing" ]   && { sleep 5; continue; }
    [ "$file" = "$last_played" ] && { sleep 3; continue; }

    last_played="$file"
    fname=${file##*/}
    title=${title:-$fname}
    [ -n "$date" ] && title="${title} ($date)"

    img=$(md5sum "$file" | awk '{print $1".jpg"}')
    img="${COVER}/${img}"
    [ -f "$img" ] || ffmpeg -v -8 -i "$file" "$img"
    [ -f "$img" ] || img="$DEFAULT_ICON"

    dunstify -r "$NID" -i "$img" \
        "[cmus] ♫ Playing now..." "${title}\n${artist}${album}${duration}"

done
