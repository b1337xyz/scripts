#!/usr/bin/env bash
# shellcheck disable=SC2155
# shellcheck disable=SC2154
declare -r -x UEBERZUG_FIFO=$(mktemp --dry-run --suffix "fzf-$$-ueberzug")
declare -r -x WIDTH=35 # image width
declare -r -x HEIGHT=22
declare -r -x mpvhist=~/.cache/mpv/mpvhistory.log
declare -r -x cache_dir=~/.cache/fzfanime_preview
[ -d "$cache_dir" ] || mkdir "$cache_dir"

function start_ueberzug {
    mkfifo "${UEBERZUG_FIFO}"

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

    jobs -p | xargs -r kill 2>/dev/null
    rm "$UEBERZUG_FIFO" "$tmpfile" "$mainfile" "$mode" &>/dev/null
}
function check_link {
    p=$(readlink -m "${ANIME_DIR}/$1")
    #p=$(stat -c '%N' "${ANIME_DIR}/$1" |
    #    awk -F' -> ' '{
    #        print substr($2, 2, length($2)-2)
    #    }'
    #)
    x=$p
    [ "${#x}" -gt "$((COLUMNS - 1))" ] &&
        x=${x::$((COLUMNS - 4))}...
    printf '%s\n' "$x"

    if [ -f "$mpvhist" ];then
        last_ep=$(grep -F "/${1}/" "$mpvhist" | tail -n1)
        last_ep=${last_ep##*/}
        if [ -f "${p}/${last_ep}" ];then
            #[ "${#last_ep}" -gt "$((COLUMNS - 15))" ] &&
            #   last_ep=${last_ep::$((COLUMNS - 15))}...
            printf 'Continue: \e[1;32m%s\e[m\n' "$last_ep"
        fi
    fi

    declare -a files=()
    cache="${cache_dir}/${1}"
    if [ -e "$p" ];then
        [ -f "$cache" ] && rm "$cache"
        ext_ptr='.*\.\(webm\|mkv\|avi\|mp4\|ogm\|mpg\|rmvb\)$'
        size=$(du -sh "$p" | awk '{print $1}')
        echo "$size" >> "$cache"

        while IFS= read -r -d $'\0' i;do
            files+=("$i")
            echo "$i"
        done < <(find "$p" -iregex "$ext_ptr" -printf '%f\0' | sort -z) >> "$cache"
    elif [ -s "$cache" ];then
        #size=$(head -1 "$cache")
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
            #[ "${#x}" -gt "$((COLUMNS - 1))" ] &&
            #    x=${x::$((COLUMNS - 4))}...

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
    IFS='|' read -r title _type genres episodes score rated image < <(\
        jq -r '.["'"${1}"'"] | "
        \(.["title"])|
        \(.["type"])|
        \(.["genres"] | join(", "))|
        \(.["episodes"])|
        \(.["score"])|
        \(.["rated"])|
        \(.["image"])"' ~/.cache/anilist.json 2>/dev/null | sed 's/^\s*//g' | tr -d \\n)

    if [ -z "$title" ];then
        # bash
        # >"${UEBERZUG_FIFO}" declare -A -p cmd=([action]="remove" [identifier]="preview")

        # json
        printf '{"action": "remove", "identifier": "preview"}\n' > "$UEBERZUG_FIFO"

        printf "404 - preview not found\n\n"
        for _ in $(seq $((COLUMNS)));do printf '─' ;done ; echo
        check_link "$1"
        return 1
    fi

    # _type=$(jq -r 'keys[] as $k | select(.[$k]["mal_id"]=='"$idMal"') | .[$k]["_type"]' \
    #    ~/.cache/maldb.json 2>/dev/null | head -n1)
    # mal_score=$(jq -r 'keys[] as $k | select(.[$k]["mal_id"]=='"$idMal"') | .[$k]["score"]' \
    #    ~/.cache/maldb.json 2>/dev/null | head -n1)

    # bash
    # >"${UEBERZUG_FIFO}" declare -A -p cmd=( \
    #     [action]=add [identifier]="preview" \
    #     [x]="0" [y]="0" \
    #     [width]="$WIDTH" [height]="22" \
    #     [scaler]=distort [scaling_position_x]=0.5 [scaling_position_y]=0.5 \
    #     [path]="$image") &

    # json
    printf '{"action": "add", "identifier": "preview", "x": "%d", "y": "%d", "width": "%d", "height": "%d", "scaler": "distort", "path": "%s"}\n' \
        0 0 "$WIDTH" "$HEIGHT" "$image" > "$UEBERZUG_FIFO" &


    #if [ "${#title}" -gt 28 ];then
    #    title=${title::28}
    #    title=${title}...
    #fi
    #if [ "${#genres}" -gt 32 ];then
    #    genres=${genres::32}
    #    genres=${genres}...
    #fi

    printf '%'$WIDTH's %s\n'           ' ' "$title"
    printf '%'$WIDTH's Type: %s\n'        ' ' "${_type:-Unknown}"
    printf '%'$WIDTH's Genre: %s\n'       ' ' "$genres"
    printf '%'$WIDTH's Episodes: %s\n'    ' ' "$episodes"
    printf '%'$WIDTH's Score: %s\n'       ' ' "$score"
    printf '%'$WIDTH's Rated: %s\n'       ' ' "$rated"
    # printf '%'$WIDTH'Mal score: %s\n'   ' ' "$mal_score"
    grep -qxF "$1" "$WATCHED_FILE" 2>/dev/null &&
        printf '%'$WIDTH's \e[1;32mWatched\e[m' ' '

    for _ in {1..17};do echo ;done
    for _ in $(seq $((COLUMNS)));do printf '─' ;done ; echo
    check_link "$1" &
}
export -f preview check_link
