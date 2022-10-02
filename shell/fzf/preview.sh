#!/usr/bin/env bash
declare -r -x UEBERZUG_FIFO=$(mktemp --dry-run --suffix "fzf-$$-ueberzug")

function start_ueberzug {
    mkfifo "$UEBERZUG_FIFO"

    # bash
    # <"${UEBERZUG_FIFO}" \
    #     ueberzug layer --parser bash --silent &
    # # prevent EOF
    # 3>"${UEBERZUG_FIFO}" \
    #     exec

    # json
    tail --follow "$UEBERZUG_FIFO" | ueberzug layer --parser json &
}
function finalise {
    # bash
    # 3>&- \
    #     exec

    # json
    printf '{"action": "remove", "identifier": "preview"}\n' > "$UEBERZUG_FIFO"

    jobs -p | xargs -r kill
    rm "$UEBERZUG_FIFO" 2>/dev/null
}
function calculate_position {
    < <(</dev/tty stty size) \
        read -r TERMINAL_LINES TERMINAL_COLUMNS

    case "${DEFAULT_PREVIEW_POSITION:-left}" in
        left|up|top) X=0 Y=0 ;;
        right) X=$((TERMINAL_COLUMNS - COLUMNS - 2)) Y=1    ;;
        down|bottom) X=1 Y=$((TERMINAL_LINES - LINES - 1))  ;;
    esac
}
function draw_preview {
    local img
    calculate_position
    file -Lbi -- "$1" 2>/dev/null | grep -q '^image/' || return 1
    img=$(printf '%s\n' "$1" | sed 's/"/\\&/g')

    # bash
    # >"${UEBERZUG_FIFO}" declare -A -p cmd=( \
    #     [action]=add [identifier]="preview" \
    #     [x]="${X}" [y]="${Y}"               \
    #     [width]="$((COLUMNS - 1))" [height]="$(( LINES - 1 ))" \
    #     [scaler]=fit_contain [scaling_position_x]=0.5 [scaling_position_y]=0.5 \
    #     [path]="$1")

    # json
    printf '{
        "action": "add", "identifier": "preview",
        "x": %d, "y": %d, "width": %d, "height": %d,
        "scaler": "fit_contain", "path": "%s"
    }\n' "$X" "$Y" "$((COLUMNS - 1))" "$((LINES - 1))" "$img" | jq -Mc > "$UEBERZUG_FIFO"

}
export -f draw_preview calculate_position 
