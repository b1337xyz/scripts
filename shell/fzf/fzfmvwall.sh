#!/usr/bin/env bash
# shellcheck disable=SC2155
declare -r -x DEFAULT_PREVIEW_POSITION="right"
declare -r -x UEBERZUG_FIFO=$(mktemp --dry-run --suffix "fzf-$$-ueberzug")
declare -r -x PREVIEW_ID="preview"
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

function calculate_position {
    < <(</dev/tty stty size) \
        read -r TERMINAL_LINES TERMINAL_COLUMNS

    case "${DEFAULT_PREVIEW_POSITION}" in
        left|up|top) X=1 Y=1 ;;
        right) X=$((TERMINAL_COLUMNS - COLUMNS - 2)) Y=1 ;;
        down|bottom) X=1 Y=$((TERMINAL_LINES - LINES - 1)) ;;
    esac
}
wallpapers() {
    if [ -d "$1" ];then
        while read -r i;do
            mv -n "$i" "$1" 1>&2
        done < "$tmpfile"
        rm -f "$tmpfile"
    elif [ -f "$1" ];then
        for i in "$@";do
            [ -f "$i" ] && echo "$i"
        done > "$tmpfile"
        find ~/Pictures/wallpapers -mindepth 1 -type d | sort
        return
    fi
    find . -maxdepth 1 -iname '*.jpg' | sort
}
function preview {
    [[ "${1##*.}" =~ jpg ]] || return

    calculate_position

    # shellcheck disable=SC2154
    >"${UEBERZUG_FIFO}" declare -A -p cmd=( \
        [action]=add [identifier]="${PREVIEW_ID}" \
        [x]="${X}" [y]="${Y}" \
        [width]="${COLUMNS}" [height]="${LINES}" \
        [scaler]=fit_contain [scaling_position_x]=0.5 [scaling_position_y]=0.5 \
        [path]="${@}")
}
export -f preview calculate_position wallpapers

trap finalise EXIT SIGINT
start_ueberzug

find . -maxdepth 1 -iname '*.jpg' | fzf -0 -m --preview "preview {}" \
    --preview-window "${DEFAULT_PREVIEW_POSITION}:60%:border-sharp" \
    --bind 'enter:reload(wallpapers {+})+clear-query+first' \
    --bind 'ctrl-d:execute(rm {})+reload(wallpapers)+refresh-preview'
