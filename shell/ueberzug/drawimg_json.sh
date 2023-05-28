#!/usr/bin/env bash
set -e 
FIFO=/tmp/ub.fifo
path=$1

mkfifo "$FIFO"
end() {
    # printf '{"action": "remove", "identifier": "test"}\n' > "$FIFO"
    jobs -p | xargs -r kill
    rm "$FIFO" 2>/dev/null
}
trap end EXIT
tail --follow "$FIFO" | ueberzug layer --parser json &

clear
read -r height width < <(</dev/tty stty size)
width=$((width - 2))
height=$((height - 2))
printf '{"action": "add", "identifier": "test", "x": "%s", "y": "%s", "width": "%s", "height": "%s", "scaler": "contain", "path": "%s"}\n' \
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

read -r -s -n1
