#!/usr/bin/env bash
# shellcheck disable=SC2001
# shellcheck disable=SC2155

API_URL="https://api.jikan.moe/v4/anime"

show_help() {
    cat << EOF
Usage: $NAME [options]

Options:
    -h --help           show this message
    -l --limit
    -p --page
    -t --type           anime,tv,ova,movie,special,ona
    -s --sort           ascending(asc),descending(desc)
    -g --genre          
    -r --rated          g (All ages), pg (Children), pg13 (13+), r17 (17+)
                        r (Adult), rx (Hentai)
    -o --order          title, start_date, end_date, score, type, members, id, 
                        episodes, rating
    --start_date        yyyy-mm-dd
    --end_date          yyyy-mm-dd
    --producer          MAL ID
    --magazine          MAL ID
    --score             0.0-10.0
    --letter
    --status            airing, completed, upcoming (tba)
    --genre_exclude
    -so --sort-output   sort output
EOF
    exit "${1:-0}"
}
[ -z "$1" ] && show_help 1


url="${API_URL}?q="
while [ -n "$1" ];do
    case "$1" in
        -p|--page) shift; url+="&page=$1" ;;
        -t|--type) shift; url+="&type=$1" ;;
        -s|--sort) shift; url+="&sort=$1" ;;
        -l|--limit) shift; url+="&limit=$1" ;;
        -g|--genre) shift; url+="&genre=$1" ;;
        -r|--rating) shift; url+="&rating=$1" ;;
        -o|--order) shift; url+="&order_by=$1" ;;
        --sfw) shift; url+="&sfw=$1" ;;
        --start_date) shift; url+="&start_date=$1" ;;
        --end_date) shift; url+="&end_date=$1" ;;
        --producer) shift; url+="&producer=$1" ;;
        --magazine) shift; url+="&magazine=$1" ;;
        --score) shift; url+="&score=$1" ;;
        --letter) shift; url+="&letter=$1" ;;
        --status) shift; url+="&status=$1" ;;
        --genre_exclude) shift; url+="&genre_exclude=$1" ;;
        -h|--help) show_help ;;
        -*) printf 'Invalid option: %s\n' "$1"; show_help 1 ;;
        *) query+="${1,,} " ;;
    esac
    shift
done
if [ -n "$query" ];then
    query="${query::-1}"
    [ "${#query}" -lt 3 ] && {
        printf 'MAL only processes queries with a minimum of 3 letters.\n'; exit 1;
    }
    query=$(fix_url_query.py "$query")
    url=${url/?q=/?q=$query}
fi
printf '%s\n' "$url" >&2

search() {
    ptr='.[] | "\(.["title"])|\(.["type"])|\(.["aired"].prop.from.year)|\(.["episodes"])|\(.["score"])|\(.["rating"])"'
    curl -s "$url" | jq -c -M '.["data"]' | jq -r "$ptr"
}

search | while IFS='|' read -r title type year episodes score rating;do

    title=$(printf '%s' "$title" | sed 's/^\s*//; s/\s*$//; s/:/ /g; s/\s\{2,\}/ /g')
    rating=${rating%% *}
    case "$rating" in
        G)      rating=$'\e[1;32mG\e[m'      ;;
        PG)     rating=$'\e[1;36mPG\e[m'     ;;
        PG-13)  rating=$'\e[1;34mPG-13\e[m'  ;;
        R)      rating=$'\e[1;33mR\e[m'      ;;
        R+)     rating=$'\e[1;31mR+\e[m'     ;;
        Rx)     rating=$'\e[1;35mRx\e[m'     ;;
    esac

    < <(</dev/tty stty size) \
        read -r _ cols
    
    max_len=$((cols / 2))
    if [ "${#title}" -gt $max_len ];then
        len=$((max_len - 3))
        title="${title::len}..."
    fi
    printf '%-'$max_len's | %-8s | %-4s | %-4s | %s\n' "$title ($year)" "$type" "$episodes" "$score" "$rating"
done
