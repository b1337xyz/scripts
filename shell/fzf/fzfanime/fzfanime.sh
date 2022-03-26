#!/usr/bin/env bash
# shellcheck disable=SC2155
# NOTE: grep -xFf <patterns list> <file> ...  will keep the order of the second file

set -eo pipefail

# USER SETTINGS

declare -r -x ANIME_DIR=~/Videos/Anime
declare -r -x DB=~/.cache/anilist.json
declare -r -x PLAYER='mpv --really-quiet=yes --profile=big-cache'

# END OF USER SETTINGS

[ -d "$ANIME_DIR" ] || { printf '%s not found\n' "${ANIME_DIR}"; exit 1; }

declare -r -x ANIME_HST=~/.cache/anime_history.txt
declare -r -x WATCHED_FILE=~/.cache/watched_anime.txt
declare -r -x mainfile=$(mktemp) 
declare -r -x tmpfile=$(mktemp)
declare -r -x mode=$(mktemp)

rpath=$(realpath "$0")
# shellcheck disable=SC1091
source "${rpath%/*}/preview.sh" || {
    printf 'Failed to source %s\n' "${rpath%/*}/preview.sh";
    exit 1;
}

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

    rm "$UEBERZUG_FIFO" "$tmpfile" "$mainfile" "$mode" &>/dev/null
}
function sed_scape {
    i=${1//\[/\\[}  i=${i//\]/\\]}
    i=${i//\*/\\*}  i=${i//\./\\.}
    i=${i//\$/\\$}  i=${i//^/\^}
    printf '%s' "$i"
}
function play {
    [ -e "${ANIME_DIR}/$1" ] || return 1
    notify-send -t 1000 -i mplayer "MPV" "Anime: $1" 2>/dev/null
    $PLAYER "${ANIME_DIR}/$1" &>/dev/null &
    echo "$1" >> "$ANIME_HST"
}
function main() {
    case "$1" in
        add_watched)
            grep -qxF "$2" "$WATCHED_FILE" 2>/dev/null ||
                printf '%s\n' "$2" >> "$WATCHED_FILE"
        ;;
        del_watched)
            if grep -qxF "$2" "$WATCHED_FILE" 2>/dev/null;then
                i=$(sed_scape "$2")
                sed -i "/${i}/d" "$WATCHED_FILE" 2>/dev/null
            fi
        ;;
        avail)
            grep -vxFf <(find "$ANIME_DIR" -mindepth 1 -maxdepth 1 \
                -xtype l -printf '%f\n') "$mainfile" | tee "$tmpfile"
        ;;
        offline)
            grep -xFf <(stat -c '%N' "$ANIME_DIR"/* | grep -vP '(onedrive|gdrive)' |
                awk -F' -> ' '{print $1}' | cut -d'/' -f6 | sed 's/.$//g') "$mainfile" | tee "$tmpfile"
        ;;
        by_score)
            grep -xFf "$mainfile" <(
            jq -r '[ keys[] as $k | .[$k] | {"title": $k, "score": .["score"]}] | sort_by(.score) | .[].title' "$DB") | tee "$tmpfile"
        ;;
        by_year)
            sed 's/.*(\([0-9]\{4\}\)).*/\1;\0/g' "$mainfile" | sort -n | sed 's/^[0-9]\{4\}\;//g' | tee "$tmpfile"
        ;;
        by_episodes)
            grep -xFf "$mainfile" <(
            jq -r '[keys[] as $k | {id: "\($k)", episodes: .[$k]["episodes"]}] | sort_by(.episodes)[] | .id' "$DB") | tee "$tmpfile"
        ;;
        watched)
            grep -xFf "$mainfile" "$WATCHED_FILE" | tac | tee "$tmpfile"
        ;;
        unwatched)
            grep -xvFf "$WATCHED_FILE" "$mainfile" | tee "$tmpfile"
        ;;
        history)
            grep -xFf "$mainfile" <(tac "$ANIME_HST" | awk '!seen[$0]++') | tee "$tmpfile"
        ;;
        continue)
            grep -vxFf "$WATCHED_FILE" <(grep -xFf "$mainfile" <(
                tac "$ANIME_HST" | awk '!seen[$0]++')) | tee "$tmpfile"
        ;;
        genre) 
            printf "genres" > "$mode"
            jq -r '.[]["genres"][]' "$DB" | sed 's/^$/Unknown/g' | sort -u
            return
        ;;
        type)
            printf "type" > "$mode"
            jq -r '.[]["type"]' "$DB" | sed 's/^$/Unknown/g' | sort -u
            return
        ;;
        rated)
            printf 'rated' > "$mode"
            jq -r '.[]["rated"]' "$DB" | sed 's/\(^$\|null\)/Unknown/g;' | sort -u
            return
        ;;
        path)
            printf "path" > "$mode"
            readlink "$ANIME_DIR"/* |
                awk '
                    {
                        split($1, a, "/");
                        x=a[length(a)-2];
                        if (x == "..") {
                            print a[length(a)-1]
                        } else {
                            print x
                        }
                    }' | sort -u
            return
        ;;
        contain)
            for i in $2 ;do
                jq -r 'keys[] as $k | select(.[$k]["synopsis"] | contains("'"$i"'")) | $k' "$DB" 
            done | tee "$tmpfile"
        ;;
        select)
            curr_mode=$(cat "$mode")
            if [ "$curr_mode" = genres ];then

                if [ "$2" = "Unknown" ];then
                    grep -xFf <(jq -r 'keys[] as $k | select(.[$k]["genres"] == [""]) | $k' "$DB") "$mainfile"
                else
                    grep -xFf <(jq -r 'keys[] as $k | select(.[$k]["'"$curr_mode"'"] | index("'"$2"'")) | $k' "$DB") \
                        "$mainfile"
                fi | tee "$tmpfile"

            elif [[ "$curr_mode" =~ (type|rated) ]];then

                grep -xFf <(jq -r 'keys[] as $k | select(.[$k]["'"$curr_mode"'"] == "'"${2/Unknown/}"'") | $k' "$DB") \
                    "$mainfile" | tee "$tmpfile"

            elif [ "$curr_mode" = "path" ];then

                stat -c '%N' "$ANIME_DIR"/* |
                    awk -F' -> ' '/'"$2"'/{split($1, a, "/"); x=a[length(a)]; print substr(x, 1, length(x) - 1) }' | tee "$tmpfile"

            else
                play "$2"
                cat "$mainfile"
            fi
        ;;
        nsfw)
            jq -Sr 'keys[] as $k | select(.[$k].isAdult) | $k' "$DB" | tee "$mainfile"
        ;;
        *)
            find "$ANIME_DIR" -mindepth 1 -maxdepth 1 -printf '%f\n' | sort | tee "$mainfile"
        ;;
    esac

    [ -f "$mode" ] && rm "$mode"
    [ -s "$tmpfile" ] && mv -f "$tmpfile" "$mainfile"
}

export -f main play sed_scape preview check_link

trap finalise EXIT SIGINT
start_ueberzug 2>/dev/null

main "$@" | fzf -e --no-sort --preview 'preview {}' \
    --color 'gutter:-1,bg+:-1,fg+:6:bold,hl+:1,hl:1,border:7:bold,header:6:bold,info:7,pointer:1' \
    --preview-window 'left:53%:border-sharp:border-right' \
    --prompt "NORMAL " \
    --border none \
    --header '^p ^s ^l ^r ^w ^o ^a ^e ^g ^v 
A-p A-u A-c A-a A-d' \
    --bind 'ctrl-t:last' \
    --bind 'ctrl-b:first' \
    --bind 'enter:reload(main select {})+clear-query' \
    --bind 'ctrl-p:execute-silent(play {})' \
    --bind 'ctrl-r:reload(main)+first+change-prompt(NORMAL )' \
    --bind 'ctrl-h:reload(main nsfw)+first+change-prompt(ADULT )' \
    --bind 'ctrl-a:reload(main avail)+change-prompt(AVAILABLE )' \
    --bind 'ctrl-y:reload(main by_year)+first+change-prompt(BY YEAR )' \
    --bind 'ctrl-s:reload(main by_score)+first+change-prompt(BY SCORE )' \
    --bind 'ctrl-e:reload(main by_episodes)+first+change-prompt(BY EPISODE )' \
    --bind 'ctrl-o:reload(main offline)+change-prompt(OFFLINE )' \
    --bind 'ctrl-w:reload(main watched)+first+change-prompt(WATCHED )' \
    --bind 'ctrl-l:reload(main history)+first+change-prompt(HISTORY )' \
    --bind 'ctrl-g:reload(main genre)+first+change-prompt(GENRE )' \
    --bind 'ctrl-v:reload(main type)+first+change-prompt(TYPE )' \
    --bind 'alt-s:reload(main contain {q})+first+change-prompt(CONTAIN )' \
    --bind 'alt-p:reload(main path)+first+change-prompt(PATH )' \
    --bind 'alt-r:reload(main rated)+first+change-prompt(RATED )' \
    --bind 'alt-u:reload(main unwatched)+change-prompt(UNWATCHED )' \
    --bind 'alt-c:reload(main continue)+first+change-prompt(CONTINUE )' \
    --bind 'alt-a:execute-silent(main add_watched {})+refresh-preview' \
    --bind 'alt-d:execute-silent(main del_watched {})+refresh-preview'
