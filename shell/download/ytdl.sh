#!/bin/sh

SCRIPT="${0##*/}"
URL="$1"
DIR=~/Downloads/ytdl
HST=~/.cache/ytdl_history

notify() {
    notify-send -i document-save "$@"
}

mkdir -p "$DIR"
echo "$URL" >> "$HST"
printf '\033]2;%s\007' "$URL"

notify "$SCRIPT started" "$URL"
if yt-dlp -P "$DIR" "$URL"
then
    notify "$SCRIPT successed" "$URL"
    exit 0
else
    notify-send -i dialog-error "$SCRIPT failed" "$URL"
    exit 1
fi
