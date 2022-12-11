#!/usr/bin/env bash
# shellcheck disable=SC2155
# Notes:
#   - grep -xFf <file1> <file2> ...  will keep the order of the second file
#   - $DB generated using Anilist APIv2 -> https://anilist.gitbook.io/anilist-apiv2-docs
#     and Jikan APIv4 -> https://api.jikan.moe/v4/anime
#     {
#       "<Anime> (1998)": {
#         "idMal": 400,
#         "isAdult": false,
#         "title": "Anime",
#         "year": 1998,
#         "genres": ["Action", ...],
#         "episodes": 24,
#         "score": 74,
#         "image": "<local path to the image>",
#         "type": "TV",
#         "rated": "R+",
#         "duration": 25,
#       }
#     }, ...


### USER SETTINGS

declare -r -x ANIME_DIR=~/Videos/Anime
declare -r -x PLAYER='mpv --profile=fzfanime'
declare -r -x DB=~/.scripts/python/myanimedb/anilist.json
declare -r -x MALDB=~/.scripts/python/myanimedb/maldb.json
declare -r -x ANIMEHIST=~/.cache/anime_history.txt
declare -r -x WATCHED_FILE=~/.cache/watched_anime.txt
declare -r -x MPVHIST=~/.cache/mpv/mpvhistory.log
[ "$DISPLAY" ] && declare -r -x BACKEND=w3m # ueberzug kitty

### END OF USER SETTINGS

# set -eo pipefail

[ -d "$ANIME_DIR" ] || { printf '%s not found\n' "${ANIME_DIR}"; exit 1; }

root=$(realpath "$0") root=${root%/*}
# shellcheck disable=SC1091
source "${root}/preview.sh" || {
    printf 'Failed to source %s\n' "${root}/preview.sh";
    exit 1;
}

declare -r -x PREVIEW_FIFO=/tmp/fzfanime.fifo
if [ "$PREVIEW_MODE" ];then
    sleep 1
    [ "$BACKEND" = "ueberzug" ] && start_ueberzug >/dev/null 2>&1
    while :;do
        while read -r i; do
            [ "$i" = "die" ] && exit 0
            preview "$i"
        done < "$PREVIEW_FIFO"
    done
    exit 0
fi

mkfifo "$PREVIEW_FIFO"
tmux split-window -h -d -l '53%' -e "PREVIEW_MODE=1" "$0"
tmux swap-pane -D

preview_fifo() {
    echo "$1" | tee "$PREVIEW_FIFO"
}
export -f preview_fifo

declare -r -x mainfile=$(mktemp --dry-run) 
declare -r -x tempfile=$(mktemp --dry-run)
declare -r -x modefile=$(mktemp --dry-run)

function play {
    [ -e "${ANIME_DIR}/$1" ] || return 1
    echo "$1" >> "$ANIMEHIST"
    if command -v devour >/dev/null 2>&1;then
        devour $PLAYER "${ANIME_DIR}/$1" >/dev/null 2>&1
    else
        nohup  $PLAYER "${ANIME_DIR}/$1" >/dev/null 2>&1 & disown
    fi
}
function main {
    # filters
    case "$1" in
        add_watched)
            grep -qxF "$2" "$WATCHED_FILE" 2>/dev/null ||
                printf '%s\n' "$2" >> "$WATCHED_FILE"
        ;;
        del_watched)
            if grep -qxF "$2" "$WATCHED_FILE" 2>/dev/null;then
                echo "$2" | sed -e 's/[]\[\*\$]/\\\\&/g' | xargs -rI{} sed -i "/{}/d" "$WATCHED_FILE"
            fi
        ;;
        avail)
            grep -vxFf <(find "$ANIME_DIR" -mindepth 1 -maxdepth 1 \
                -xtype l -printf '%f\n') "$mainfile" | tee "$tempfile"
        ;;
        by_score)
            grep -xFf "$mainfile" <(jq -r \
            '[ keys[] as $k | .[$k] | {"title": $k, "score": .["score"]}] | sort_by(.score) | .[].title' "$DB") |
            tee "$tempfile"
        ;;
        by_year)
            sed 's/.*(\([0-9]\{4\}\)).*/\1;\0/g' "$mainfile" | sort -n | sed 's/^[0-9]\{4\}\;//g' | tee "$tempfile"
        ;;
        by_episodes)
            grep -xFf "$mainfile" <(jq -r \
            '[keys[] as $k | {id: "\($k)", episodes: .[$k]["episodes"]}] | sort_by(.episodes)[] | .id' "$DB") |
            tee "$tempfile"
        ;;
        watched)
            grep -xFf "$mainfile" "$WATCHED_FILE" | tac | tee "$tempfile"
        ;;
        unwatched)
            grep -xvFf "$WATCHED_FILE" "$mainfile" | tee "$tempfile"
        ;;
        history)
            grep -xFf "$mainfile" <(tac "$ANIMEHIST" | awk '!seen[$0]++') | tee "$tempfile"
        ;;
        continue)
            grep -vxFf "$WATCHED_FILE" <(grep -xFf "$mainfile" <(
                tac "$ANIMEHIST" | awk '!seen[$0]++')) | tee "$tempfile"
        ;;
        latest)
            # grep -xFf "$mainfile" <(ls --color=never -N1Ltc "$ANIME_DIR") | tee "$tempfile"
            awk -v p="$ANIME_DIR" '{printf("%s/%s\0", p, $0)}' "$mainfile" |
                xargs -r0 ls --color=never -dN1Ltc | grep -oP '[^/]*$' | tee "$tempfile"
        ;;
        shuffle) shuf "$mainfile" ;;
        by_size)
            awk -v p="$ANIME_DIR" '{printf("%s/%s\0", p, $0)}' "$mainfile" |
                du -L --files0-from=- | sort -n | grep -oP '[^/]*$' | tee "$tempfile"
        ;;
        genre) 
            printf "genres" > "$modefile"
            # jq -r '.[].genres | if . == [] then "Unknown" else "\(.[])" end' "$DB" | sort -u
            jq -r '.[] | .genres[] // "Unknown"' "$DB" | sort -u
            return
        ;;
        type)
            printf "type" > "$modefile"
            jq -r '.[] | .type // "Unknown"' "$DB" | sort -u
            return
        ;;
        rated)
            printf 'rated' > "$modefile"
            jq -r '.[] | .rated // "Unknown"' "$DB" | sort -u
            return
        ;;
        path)
            printf "path" > "$modefile"
            readlink "$ANIME_DIR"/* | awk '{
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
        select)
            curr_mode=$(<"$modefile")
            if [ "$curr_mode" = genres ];then
                if [ "$2" = "Unknown" ];then
                    grep -xFf <(jq -r 'keys[] as $k | select(.[$k]["genres"] == []) | $k' "$DB") "$mainfile"
                else
                    grep -xFf <(jq -r --arg mode "$curr_mode" --arg v "$2" \
                        'keys[] as $k | select(.[$k][$mode] | index($v)) | $k' "$DB") "$mainfile"
                fi | tee "$tempfile"
            elif [[ "$curr_mode" =~ (type|rated) ]];then
                if [ "$2" = "Unknown" ];then
                    grep -xFf <(jq -r --arg mode "$curr_mode" \
                        'keys[] as $k | select(.[$k][$mode] | not) | $k' "$DB") "$mainfile"
                else
                    grep -xFf <(jq -r --arg mode "$curr_mode" --arg v "$2" \
                        'keys[] as $k | select(.[$k][$mode] == $v) | $k' "$DB") "$mainfile"
                fi | tee "$tempfile"
            elif [ "$curr_mode" = "path" ];then
                stat -c '%N' "$ANIME_DIR"/* | awk -F' -> ' -v mode="$2" \
                    '$0 ~ mode {split($1, a, "/"); x=a[length(a)]; print substr(x, 1, length(x) - 1) }' |
                    tee "$tempfile"
            else
                play "$2"
                cat "$mainfile"
            fi
        ;;
        adult)
            jq -Sr 'keys[] as $k | select(.[$k].isAdult) | $k' "$DB" | tee "$mainfile"
        ;;
        *)
            jq -Sr 'keys[] as $k | select(.[$k].isAdult | not) | $k' "$DB" | tee "$mainfile"
            # find "$ANIME_DIR" -mindepth 1 -maxdepth 1 -printf '%f\n' | sort | tee "$mainfile"
        ;;
    esac

    [ -f "$modefile" ] && rm "$modefile"
    [ -f "$tempfile" ] && mv -f "$tempfile" "$mainfile"
}
export -f main play

trap finalise EXIT HUP INT

n=$'\n'
# --color 'gutter:-1,bg+:-1,fg+:6:bold,hl+:1,hl:1,border:7:bold,header:6:bold,info:7,pointer:1' \
main "$@" | fzf -e --no-sort --color dark \
    --preview='preview_fifo {}' \
    --preview-window='down,border-none,1' \
    --border none --no-separator --prompt "NORMAL " \
    --header "^p ^s ^l ^r ^w ^o ^a ^e ^g ^v${n}A-p A-u A-c A-a A-d A-s" \
    --bind 'ctrl-t:last' \
    --bind 'ctrl-b:first' \
    --bind 'enter:reload(main select {})+clear-query' \
    --bind 'ctrl-d:delete-char' \
    --bind 'ctrl-p:execute-silent(play {})' \
    --bind 'ctrl-r:reload(main)+first+change-prompt(NORMAL )' \
    --bind 'ctrl-h:reload(main adult)+first+change-prompt(ADULT )' \
    --bind 'ctrl-a:reload(main avail)+change-prompt(AVAILABLE )' \
    --bind 'ctrl-y:reload(main by_year)+first+change-prompt(BY YEAR )' \
    --bind 'ctrl-s:reload(main by_score)+first+change-prompt(BY SCORE )' \
    --bind 'ctrl-e:reload(main by_episodes)+first+change-prompt(BY EPISODE )' \
    --bind 'ctrl-w:reload(main watched)+first+change-prompt(WATCHED )' \
    --bind 'ctrl-l:reload(main history)+first+change-prompt(HISTORY )' \
    --bind 'ctrl-g:reload(main genre)+first+change-prompt(GENRE )' \
    --bind 'ctrl-v:reload(main type)+first+change-prompt(TYPE )' \
    --bind 'alt-l:reload(main latest)+first+change-prompt(LATEST )' \
    --bind 'alt-p:reload(main path)+first+change-prompt(PATH )' \
    --bind 'alt-r:reload(main rated)+first+change-prompt(RATED )' \
    --bind 'alt-s:reload(main shuffle)+first+change-prompt(SHUFFLED )' \
    --bind 'alt-u:reload(main unwatched)+change-prompt(UNWATCHED )' \
    --bind 'alt-c:reload(main continue)+first+change-prompt(CONTINUE )' \
    --bind 'alt-b:reload(main by_size)+first+change-prompt(BY SIZE )' \
    --bind 'alt-a:execute-silent(main add_watched {})+refresh-preview' \
    --bind 'alt-d:execute-silent(main del_watched {})+refresh-preview'
