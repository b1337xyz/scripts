#!/usr/bin/env bash

set -euo pipefail

PID=$$
FIFO=/tmp/cmus.ueberzug.fifo
COVER=~/.cache/thumbnails/albums
PIDFILE=/tmp/.${0##*/}.pid

# shellcheck disable=SC2046
if [ -f "$PIDFILE" ]; then
    kill -1 $(cat "$PIDFILE") || exit 1
    sleep 6
fi
echo "$PID" > "$PIDFILE"

mkfifo "$FIFO"
tail --follow "$FIFO" | ueberzug layer --parser json &

end() {
    jobs -p | xargs -r kill 2>/dev/null || true
    printf '{"action": "remove", "identifier": "test"}\n' > "$FIFO"
    rm "$FIFO" "$PIDFILE" 2>/dev/null
}
trap end EXIT

read -r lins cols < <(</dev/tty stty size)
width=25
height=12
x=$(( cols - width - 16)) 
y=$(( lins - height - 4))
prev_file=
while [ -e "$FIFO" ]; do
    curr_file=$(cmus-remote -Q | grep -oP '(?<=^file ).*')
    [ "$curr_file" = "$prev_file" ] && { sleep 5; continue; }
    prev_file=$curr_file
    img=$(md5sum "$curr_file" | awk '{print $1".jpg"}')
    img="${COVER}/${img}"
    [ -f "$img" ] || ffmpeg -v -8 -i "$curr_file" "$img"
    printf '{"action": "add", "identifier": "test", "x": "%s", "y": "%s", "width": "%s", "height": "%s", "scaler": "cover", "path": "%s"}\n' \
        "$x" "$y" "$width" "$height" "$img" > "$FIFO"
done
