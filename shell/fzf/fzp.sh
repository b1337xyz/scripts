#!/usr/bin/env bash
# shellcheck disable=SC2155
# shellcheck disable=SC1133
# shellcheck disable=SC2154
declare -r -x DEFAULT_PREVIEW_POSITION="right"
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
    rm "${UEBERZUG_FIFO}" &>/dev/null
}
function draw_preview {
    >"${UEBERZUG_FIFO}" declare -A -p cmd=( \
        [action]=add [identifier]="${PREVIEW_ID}" \
        [x]="0" [y]="0" \
        [width]="${COLUMNS}" [height]="${LINES}" \
        [scaler]=fit_contain [scaling_position_x]=0.5 [scaling_position_y]=0.5 \
        [path]="$1")
        # add [synchronously_draw]=True if you want to see each change
}

function gen_thumbnail() {
    local cache_dir cache
    cache_dir=~/.cache/sxiv_scripts
    [ -d "$cache_dir" ] || mkdir -v "$cache_dir"
    cache="${cache_dir}/files"
    [ -f "$cache" ] || touch "$cache"
    
    rpath=$(realpath "$1")
    file_size=$(command du "$rpath")
    out="${cache_dir}/${i##*/}.jpg"
    if ! grep -qF "$file_size" "$cache";then
        ffmpegthumbnailer -f -s 300 -i "$rpath" -q 10 -o "$out" 2>/dev/null
        echo "$file_size" >> "$cache"
    fi
    echo "$out"
}

fzf_preview() {
    if [ -f "$1" ];then
        mimetype=$(file -Lbi -- "$1")
        case "$mimetype" in
            image*) draw_preview "$1" ;;       
            video*) 
                [ -p "$UEBERZUG_FIFO" ] || start_ueberzug
                out=$(gen_thumbnail "$1")
                draw_preview "$out" ;;
            audio*) mediainfo "$1" ;;
            text/*) bat --style=numbers --color=always --line-range :500 "$1" ;;
            *x-rar*) unrar vt "$1" ;;
        esac
    elif [ -d "$1" ];then
        ls -1 --color=always "$1"
    fi
}
trap finalise EXIT
export -f draw_preview gen_thumbnail
export -f finalise 
export -f start_ueberzug
export -f fzf_preview
while :;do
    out=$(find . -mindepth 1 -maxdepth 1 | grep -v '\./\.' | sort |
        fzf --preview 'fzf_preview {}' \
            --preview-window "${DEFAULT_PREVIEW_POSITION}:70%"
    )
    [ -z "$out" ] && break
    if [ -d "$out" ];then
        cd "$out" || exit 1
    else
        mimetype=$(file -Lbi -- "$out")
        case "$mimetype" in
            audio/*) mpv --really-quiet=no "$out" ;;
            image/*)
                if [ "${out##*.}" = "gif" ];then
                    mpv --really-quiet --loop "$out"
                else
                    sxiv -q "$out"
                fi
            ;;
            text/*) vim "$out" ;;
            video/*) mpv "$out" ;;
            *x-bittorrent*) aria2c -S "$out" ;;
        esac
    fi
done
