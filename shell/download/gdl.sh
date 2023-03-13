#!/bin/sh
set -e

SCRIPT="${0##*/}"
URL="$1"
DIR=~/Downloads/gdl
HST=~/.cache/gdl_history

notify() {
    notify-send -i document-save "$@"
}

mkdir -p "$DIR"
echo "$@" >> "$HST"
printf '\033]2;%s\007' "$URL"

notify "$SCRIPT started" "$URL"
if gallery-dl -d "$DIR" "$URL" 2>> "$HST"
then
    notify "$SCRIPT successed" "$URL"
    exit 0
else
    notify-send -i dialog-error "$SCRIPT failed" "$URL"
    exit 1
fi
