#!/usr/bin/env bash
# shellcheck disable=SC2155
# shellcheck disable=SC2154

set -e

declare -r -x UEBERZUG_FIFO=$(mktemp --dry-run --suffix "fzf-$$-ueberzug")
declare -r -x tmpfile=$(mktemp)

function start_ueberzug {
    mkfifo "${UEBERZUG_FIFO}"
    <"${UEBERZUG_FIFO}" \
        ueberzug layer --parser bash --silent &
    # prevent EOF
    3>"${UEBERZUG_FIFO}" \
        exec
}
function finalise {
    3>&- \
        exec
    rm "${UEBERZUG_FIFO}" "$tmpfile" &>/dev/null
}
function draw_preview {
    dl_dir=~/.cache/4ch
    url=https://boards.4chan.org/aco/thread/${1}
    img=$(curl -s "$url" | grep -oP '(?<=href=")[^"]*\.(jpg|png|gif|webm)' | head -n1)
    img_path=${dl_dir}/${img##*/}
    [ -f "$img_path" ] || wget -q -nc -P "$dl_dir" "http:$img";

    < <(</dev/tty stty size) \
        read -r _ TERMINAL_COLUMNS

    >"${UEBERZUG_FIFO}" declare -A -p cmd=( \
        [action]=add [identifier]="preview" \
        [x]="$((TERMINAL_COLUMNS - COLUMNS))" [y]="0" \
        [width]="$COLUMNS" [height]="$(( LINES - 8))" \
        [scaler]=fit_contain [scaling_position_x]=0.5 [scaling_position_y]=0.5 \
        [path]="$img_path")

    for _ in $(seq "$((LINES - 8))");do echo ;done
    jq -r '.["'"$1"'"] | "\(.sub)\nImages: \(.images)"' "$tmpfile" | grep -v null
}
export -f draw_preview 

start_ueberzug
trap finalise EXIT

curl -s 'https://a.4cdn.org/aco/catalog.json' |
    jq -rc '.[]["threads"][] | {"\(.no)": {"sub": .sub, "images": .images}}' >> "$tmpfile"

jq -r 'keys[]' "$tmpfile" | fzf --border=none --preview-window 'right:90%:border-none' --preview 'draw_preview {}'

