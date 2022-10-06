#!/usr/bin/env bash
set -ex
FIFO=ub.fifo
width=50
height=50
path=$1

draw() {
printf '{"action": "add", "identifier": "test", "x": %d, "y": %d, "width": "%d", "height": "%d", "scaler": "fit_contain", "path": "%s"}\n' \
    "${x:-0}" "${y:-0}" "$width" "$height" "$path" > "$FIFO"
}

mkfifo "$FIFO"
tail --follow "$FIFO" | ueberzug layer --parser json &

draw

printf '{"action": "remove", "identifier": "test"}\n' > "$FIFO"


jobs -p | xargs -r kill
rm -v "$FIFO"
