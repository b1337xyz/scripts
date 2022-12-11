#!/usr/bin/env bash
# shellcheck disable=SC2155
# shellcheck disable=SC2154
declare -r -x W3MIMGDISPLAY=/usr/lib/w3m/w3mimgdisplay
declare -r -x UEBERZUG_FIFO=/tmp/fzfanime.ueberzug
declare -r -x WIDTH=32 # image width
declare -r -x HEIGHT=20
declare -r -x cache_dir=~/.cache/fzfanime_preview
[ -d "$cache_dir" ] || mkdir -p "$cache_dir"

function start_ueberzug {
    mkfifo "${UEBERZUG_FIFO}"
    tail --follow "$UEBERZUG_FIFO" | ueberzug layer --parser json &
}
function finalise {
    echo die > "$PREVIEW_FIFO"
    jobs -p | xargs -r kill 2>/dev/null || true
    rm "$PREVIEW_FIFO" "$tempfile" "$mainfile" "$modefile" 2>/dev/null || true
    if [ -S "$UEBERZUG_FIFO" ];then
        printf '{"action": "remove", "identifier": "preview"}\n' > "$UEBERZUG_FIFO"
        rm "$UEBERZUG_FIFO" 2>/dev/null
    fi
}
function check_link {
    max_cols=$((COLUMNS - 10))
    p=$(readlink -m "${ANIME_DIR}/$1")
    # p=$(stat -c '%N' "${ANIME_DIR}/$1" | awk -F' -> ' '{print substr($2, 2, length($2)-2)}')
    x=$p
    [ "${#x}" -gt "$max_cols" ] && x=${x::$((max_cols - 4))}...
    printf '%s\n' "$x"

    if [ -f "$MPVHIST" ];then
        last_ep=$(grep -F "/${1}/" "$MPVHIST" | tail -n1)
        last_ep=${last_ep##*/}
        if [ -f "${p}/${last_ep}" ];then
            [ "${#last_ep}" -gt "$((max_cols - 15))" ] &&
                last_ep=${last_ep::$((max_cols - 15))}...
            printf 'Continue: \e[1;32m%s\e[m\n' "$last_ep"
        fi
    fi

    declare -a files=()
    cache="${cache_dir}/${1}"
    if [ -e "$p" ]; then
        [ -f "$cache" ] && rm "$cache"
        ext_ptr='.*\.\(webm\|mkv\|avi\|mp4\|ogm\|mpg\|rmvb\)$'
        size=$(du -sh "$p" | awk '{print $1}' | tee -a "$cache")

        while IFS= read -r -d $'\0' i; do
            files+=("$i")
            echo "$i"
        done < <(find "$p" -iregex "$ext_ptr" -printf '%f\0' | sort -z) >> "$cache"
    elif [ -s "$cache" ]; then
        size=$(head -1 "$cache")
        while read -r i;do
            files+=("$i")
        done < <(tail -n +2 "$cache")
        printf '\e[1;31mUnavailable\e[m\n'
    fi

    if [ "${#files[@]}" -gt 0 ];then
        [ -n "$size" ] && printf 'Size: %s\t' "$size"
        printf 'Files: %s\n' "${#files[@]}"
        n=4
        for ((i=0;i<"${#files[@]}";i++));do
            x=${files[i]}
            [ "${#x}" -gt "$max_cols" ] && x=${x::$((max_cols - 4))}...

            if [ "$i" -lt "$n" ] || [ "${#files[@]}" -le $((n*2)) ];then
                printf '%s\n' "$x"
            elif [ "$i" -ge $(( ${#files[@]} - n )) ];then
                printf '%s\n' "$x"
            fi
        done
    else
        printf '\e[1;31mUnavailable\e[m\n'
    fi
}
function preview {
    clear
    max_cols=$((COLUMNS - 10))
    IFS=$'\n' read -d '' -r title _type genres episodes score rated image < <(\
        jq -Mr --argjson k "\"$1\"" '.[$k] |
           "\(.["title"] // "404")
            \(.["type"])
            \(.["genres"] | if length > 0 then . | join(", ") else "Unknown" end)
            \(.["episodes"] // "Unknown")
            \(.["score"] // "Unknown")
            \(.["rated"])
            \(.["image"])"' "$DB" 2>/dev/null | sed 's/^\s*//')

    [ "$BACKEND" = "kitty" ] && kitty icat --transfer-mode=file \
        --stdin=no --clear --silent >/dev/null 2>&1 </dev/tty

    if [ "$title" = "404" ];then

        [ "$BACKEND" = "ueberzug" ] &&
            printf '{"action": "remove", "identifier": "preview"}\n' > "$UEBERZUG_FIFO"

        printf "404 - preview not found\n\n"
        # for _ in $(seq $((COLUMNS)));do printf '─' ;done ; echo
        # check_link "$1"
        return 0
    fi

    [ "${#title}"  -gt "$max_cols" ] && title=${title::$((max_cols - 4))}...
    [ "${#genres}" -gt "$max_cols" ] && genres=${genres::$((max_cols - 4))}...

    printf '%'$WIDTH's %s\n'              ' ' "$title"
    printf '%'$WIDTH's Type: %s\n'        ' ' "${_type:-Unknown}"
    # printf '%'$WIDTH's Genre: %s\n'       ' ' "$genres"
    printf '%'$WIDTH's Episodes: %s\n'    ' ' "$episodes"
    printf '%'$WIDTH's Rated: %s\n'       ' ' "$rated"
    printf '%'$WIDTH's Score: %s\n'       ' ' "$score"
    # if [ -f "$MALDB" ];then
    #     mal_score=$(jq --argjson k "\"$1\"" '.[$k]["score"]' "$MALDB")
    #     printf '%'$WIDTH's Mal score: %s\n'   ' ' "$mal_score"
    # fi

    grep -qxF "$1" "$WATCHED_FILE" 2>/dev/null &&
        printf '%'$WIDTH's \e[1;32mWatched\e[m' ' '

    for _ in {1..15};do echo ;done
    # for _ in $(seq $((COLUMNS)));do printf '─' ;done ; echo
    check_link "$1" &

    case "$BACKEND" in
        kitty)
            kitty icat --transfer-mode=file \
                --stdin=no --silent --align=left --scale-up \
                --place "${WIDTH}x${HEIGHT}@0x0" "$image" >/dev/null 2>&1 </dev/tty
        ;;
        ueberzug) 
            printf '{"action": "add", "identifier": "%s", "x": 0, "y": 0, "width": %d, "height": %d, "scaler": "%s", "path": "%s"}\n' \
                "preview" "$WIDTH" "$HEIGHT" "distort" "$image" > "$UEBERZUG_FIFO"
        ;;
        w3m)
            # https://github.com/junegunn/fzf/issues/2551
            read -r width height < <(printf '5;%s' "$image" | "$W3MIMGDISPLAY")
            printf '0;1;%s;%s;%s;%s;;;;;%s\n4;\n3;' \
                "0" "0" "$width" "$height" "$image" | "$W3MIMGDISPLAY"
        ;;
    esac
}
export -f preview check_link
