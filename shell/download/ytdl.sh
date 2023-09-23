#!/bin/sh
echo "$*" >> ~/.cache/ytdl_history
notify-send -i emblem-downloads.png "[ytdl] Downloading..." "$*"
if yt-dlp -P ~/Downloads/ytdl "$@"
then
    notify-send -i document-save "[ytdl] Successed" "$*"
else
    notify-send -i dialog-error "[ytdl] Failed" "$*"
    exit 1
fi
