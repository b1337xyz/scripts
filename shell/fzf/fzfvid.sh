#!/usr/bin/env bash
# shellcheck disable=SC2155
# shellcheck disable=SC2162
declare -r -x DEFAULT_PREVIEW_POSITION="right"
declare -r -x UEBERZUG_FIFO="$(mktemp --dry-run --suffix "fzf-$$-ueberzug")"
declare -r -x THUMB_DIR=~/.cache/fzfvideo
declare -r -x list=$(mktemp)
[ -d "$THUMB_DIR" ] || mkdir -v "$THUMB_DIR"

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

    rm "${UEBERZUG_FIFO}" &>/dev/null
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
        ffmpegthumbnailer -f -s 300 -i "$1" -q 10 -o "$img"

    # shellcheck disable=SC2154
    >"${UEBERZUG_FIFO}" declare -A -p cmd=( \
        [action]=add [identifier]="${PREVIEW_ID}" \
        [x]="${X}" [y]="${Y}" \
        [width]="${COLUMNS}" [height]="${LINES}" \
        [scaler]=fit_contain [scaling_position_x]=0.5 [scaling_position_y]=0.5 \
        [path]="$img")
}
sort_by_size() {
    tr \\n \\0 < "$list" | du --files0-from=- | sort -rn | cut -d $'\t' -f2-
}
export -f draw_preview calculate_position sort_by_size

trap finalise EXIT
start_ueberzug

case "$1" in
    -) while read -r i;do echo "$i" ;done > "$list" ;;
    *)
        find "${1:-.}" -maxdepth 1 \
            -iregex '.*\.\(mkv\|avi\|mp4\|webm\)' >> "$list"
    ;;
esac

fzf -m --preview "draw_preview {}" \
    --header '^p ^r ^s' \
    --border=none \
    --disabled \
    --preview-window "${DEFAULT_PREVIEW_POSITION}:60%:border-sharp" \
    --bind 'ctrl-a:select-all' \
    --bind 'alt-a:deselect-all' \
    --bind 'ctrl-p:execute-silent(mpv {+})' \
    --bind 'ctrl-s:reload(sort_by_size)' \
    --bind 'ctrl-r:execute(rm {})' < "$list"

