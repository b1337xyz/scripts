#!/usr/bin/env bash
set -e 
FIFO=ub.fifo
path=$1
    
read -r height width < <(</dev/tty stty size)

mkfifo "$FIFO"
tail --follow "$FIFO" | ueberzug layer --parser json &

clear
printf '{"action": "add", "identifier": "test", "x": %d, "y": %d, "width": "%d", "height": "%d", "scaler": "cover", "path": "%s"}\n' \
    "${x:-0}" "${y:-0}" "$width" "$height" "$path" > "$FIFO"

read
printf '{"action": "remove", "identifier": "test"}\n' > "$FIFO"


jobs -p | xargs -r kill
rm -v "$FIFO"
