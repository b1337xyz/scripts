#!/usr/bin/env bash
declare -r -x DEFAULT_PREVIEW_POSITION="left"
declare -r -x UEBERZUG_FIFO="$(mktemp --dry-run --suffix "fzf-$$-ueberzug")"
declare -r -x PREVIEW_ID="preview"

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
    &>/dev/null \
        rm "${UEBERZUG_FIFO}"
    &>/dev/null \
        kill $(jobs -p)
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

    >"${UEBERZUG_FIFO}" declare -A -p cmd=( \
        [action]=add [identifier]="${PREVIEW_ID}" \
        [x]="${X}" [y]="${Y}" \
        [width]="${COLUMNS}" [height]="${LINES}" \
        [scaler]=fit_contain [scaling_position_x]=0.5 [scaling_position_y]=0.5 \
        [path]="${@}")
}
export -f draw_preview calculate_position

trap finalise EXIT
start_ueberzug

case "$1" in
    video)
        cache_dir=~/.cache/sxiv_scripts
        [ -d "$cache_dir" ] || mkdir -v "$cache_dir"
        cache="${cache_dir}/files"
        [ -f "$cache" ] || touch "$cache"

        declare -A files=()
        while read -r i;do
            target=$(find -L "$i" -maxdepth 1 -iregex '.*\.\(mp4\|mkv\|webm\|avi\)$' | head -n1)
            if [ -n "$target" ];then
                file_size=$(command du "$target")
                out="${cache_dir}/${target##*/}.jpg"
                files["$out"]="$i"
                if ! grep -qF "$file_size" "$cache";then
                    ffmpegthumbnailer -f -s 300 -i "$target" -q 10 -o "$out" 2>/dev/null
                    echo "$file_size" >> "$cache"
                fi
            fi
        done < <(find . -mindepth 1 -maxdepth 1)

        for k in "${!files[@]}";do echo "$k" ;done | fzf --preview "draw_preview {}" \
            --preview-window "${DEFAULT_PREVIEW_POSITION}:50%" | while read -r k;do
            printf '%s\0' "${files[$k]}"
        done | xargs -r0 mpv
    ;;
    *)
        find . -mindepth 1 -maxdepth 1 | sort -Vr | while read -r i;do
            find -L "$i" -maxdepth 1 \
                -iregex '.*\.\(jpg\|png\|jpeg\)$' | sort | head -n1
        done | fzf --preview "draw_preview {}" \
             --preview-window "${DEFAULT_PREVIEW_POSITION}:35%" |
                awk -F'/' '{print $2}' |
                xargs -rI{} sxiv -fqrs w {}
    ;;
esac
