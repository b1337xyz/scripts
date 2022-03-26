#!/usr/bin/env bash
# shellcheck disable=SC2155
# shellcheck disable=SC2162
declare -r -x DEFAULT_PREVIEW_POSITION="right"
declare -r -x UEBERZUG_FIFO="$(mktemp --dry-run --suffix "fzf-$$-ueberzug")"
declare -r -x THUMB_DIR=~/.cache/thumbnails/fzf
[ -d "$THUMB_DIR" ] || mkdir -vp "$THUMB_DIR"

WALLPAPERS=~/Videos/wallpapers

function start_ueberzug {
    mkfifo "${UEBERZUG_FIFO}"
    <"${UEBERZUG_FIFO}" \
        ueberzug layer --parser bash --silent &
    3>"${UEBERZUG_FIFO}" \
        exec
}
function finalise {
    3>&- \
        exec

    rm "${UEBERZUG_FIFO}" &>/dev/null
    # shellcheck disable=SC2046
    kill $(jobs -p) &>/dev/null
}
function calculate_position {
    < <(</dev/tty stty size) \
        read TERMINAL_LINES TERMINAL_COLUMNS

    case "${DEFAULT_PREVIEW_POSITION}" in
        left|up|top) X=1 Y=1 ;;
        right) X=$((TERMINAL_COLUMNS - COLUMNS - 1)) Y=1 ;;
        down|bottom) X=1 Y=$((TERMINAL_LINES - LINES - 1)) ;;
    esac
}
function draw_preview {
    calculate_position

    img=$THUMB_DIR/$(head -c 150 "$1" | md5sum | awk '{print $1".jpg"}')
    [ -f "$img" ] ||
        ffmpegthumbnailer -s 300 -i "$1" -q 10 -o "$img"

    # shellcheck disable=SC2154
    >"${UEBERZUG_FIFO}" declare -A -p cmd=( \
        [action]=add [identifier]="${PREVIEW_ID}" \
        [x]="${X}" [y]="${Y}" \
        [width]="${COLUMNS}" [height]="${LINES}" \
        [scaler]=fit_contain [scaling_position_x]=0.5 [scaling_position_y]=0.5 \
        [path]="$img")
}
export -f draw_preview calculate_position

trap finalise EXIT
start_ueberzug

find "${1:-$WALLPAPERS}" -iregex '.*\.\(mkv\|avi\|mp4\|webm\|gif\)' | sort |
    fzf --preview "draw_preview {}" \
    --border=none \
    --preview-window "${DEFAULT_PREVIEW_POSITION}:45%:border-sharp" \
    --bind 'ctrl-h:execute-silent(vbg.sh -s hdmi1 {})' \
    --bind 'ctrl-m:execute-silent(vbg.sh -s eDP1 {})' \
    --bind 'enter:execute-silent(vbg.sh {})'

