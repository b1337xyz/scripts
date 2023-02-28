#!/usr/bin/env bash
set -e 
FIFO=/tmp/ub.fifo
path=$1

read height width < <(</dev/tty stty size)

mkfifo "$FIFO"
end() {
    printf '{"action": "remove", "identifier": "test"}\n' > "$FIFO"
    rm "$FIFO" 2>/dev/null
}
trap end EXIT
tail --follow "$FIFO" | ueberzug layer --parser json &

clear
printf '{"action": "add", "identifier": "test", "x": "%s", "y": "%s", "width": "%s", "height": "%s", "scaler": "cover", "path": "%s"}\n' \
    "${x:-0}" "${y:-0}" "$width" "$height" "$path" > "$FIFO"

# printf '{
#     "action": "add",
#     "identifier": "test",
#     "x": "%s",
#     "y": "%s",
#     "width": "%s",
#     "height": "%s",
#     "scaler": "cover",
#     "path": "%s"
# }\n' "${x:-0}" "${y:-0}" "$width" "$height" "$path" | jq -c > "$FIFO"

read -s -n1
