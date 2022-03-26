#!/bin/sh

[ -z "$1" ] && { notify-send 'ytdl.sh' 'Nothing to do\nbye..' ; exit 1 ; }

ytdir=~/Downloads/ytdl
[ -d "$ytdir" ] || mkdir -p "$ytdir"

notify-send "ytdl-sh" "$*"
printf '\033]2;%s\007' "$@"
echo "$@" >> ~/.cache/ytdl_history

ytdl() {
    if yt-dlp -i -o "$ytdir"'/%(title)s.%(ext)s' --downloader aria2c "$@";then
        notify-send -i emblem-downloads "Download completed" "Saved at: $ytdir"
    else
        notify-send -i emblem-downloads \
            -u critical "ytdl.sh" "Download finished with erros"
    fi
}

case "$1" in
    bv) ytdl -f 'bv[width<=1920]' "$2" ;;
    audio) ytdl -x "$2" ;;
    *) ytdl -f '[width<=1920]' "$1" ;;
esac
