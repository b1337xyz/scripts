#!/bin/sh
echo "$*" >> ~/.cache/gdl_history
notify-send -i emblem-downloads.png "[gdl] Downloading..." "$*"

if gallery-dl -d ~/Downloads/gdl "$@"
then
    notify-send -i document-save "[gdl] Successed" "$*"
else
    notify-send -i dialog-error "[gdl] Failed" "$*"
    exit 1
fi
