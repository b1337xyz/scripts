#!/usr/bin/env bash
# shellcheck disable=SC2155
# shellcheck disable=SC2162
# shellcheck disable=SC2154

declare -r -x DEFAULT_PREVIEW_POSITION="right"
declare -r -x UEBERZUG_FIFO="$(mktemp --dry-run --suffix "fzf-$$-ueberzug")"
declare -r -x PREVIEW_ID="left"
declare -r -x thumbs=~/.cache/thumbnails/fonts
[ -d "$thumbs" ] || mkdir -vp "$thumbs"


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
    # shellcheck disable=SC2046
    kill $(jobs -p) &>/dev/null

}
function calculate_position {
    < <(</dev/tty stty size) \
        read TERMINAL_LINES TERMINAL_COLUMNS

    case "${DEFAULT_PREVIEW_POSITION}" in
        left|up|top) X=1 Y=1 ;;
        right) X=$((TERMINAL_COLUMNS - COLUMNS - 2)) Y=1 ;;
        down|bottom) X=1 Y=$((TERMINAL_LINES - LINES - 1)) ;;
    esac
}
function draw_preview {
    calculate_position

    font_name="${1##*/}"
    font_name="${font_name%.*}"
    image="${thumbs}/${font_name}.jpg"
    imgsize=600x800
    fontsize=42
    bgc="#000000"
    fgc="#ffffff"
    preview_text="ABCDEFGHIJKLM\nNOPQRSTUVWXYZ\n\
    abcdefghijklm\nnopqrstuvwxyz\n1234567890\n!@#$\%^&*,.;:\n_-=+'\"|\\(){}[]"

    if ! [ -f "$image" ];then
        convert -size "$imgsize" xc:"$bgc" -fill "$fgc" \
            -pointsize "$fontsize" -font "$1" -gravity center \
            -annotate +0+0 "$preview_text" "$image"
    fi

    >"${UEBERZUG_FIFO}" declare -A -p cmd=( \
        [action]=add [identifier]="${PREVIEW_ID}" \
        [x]="${X}" [y]="${Y}" \
        [width]="${COLUMNS}" [height]="${LINES}" \
        [scaler]=forced_cover [scaling_position_x]=0.5 [scaling_position_y]=0.5 \
        [path]="$image")
}
export -f draw_preview calculate_position

trap finalise EXIT
start_ueberzug

font_path=$(fc-list -f '%{file}\n' | grep -v '\.gz$' | sort -uV | fzf --preview "draw_preview {}" \
    --preview-window "${DEFAULT_PREVIEW_POSITION}:48%")

[ -z "$font_path" ] && exit 1
fc-list | grep -F "${font_path}" | xclip -sel clip
notify-send "Clipboard" "$(xclip -o)"
