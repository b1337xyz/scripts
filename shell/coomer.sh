#!/usr/bin/env bash
# shellcheck disable=SC2086

# Dependencies:
#   https://github.com/meganz/MEGAcmd
#   https://github.com/prasmussen/gdrive
#   https://github.com/yt-dlp/yt-dlp
#   https://github.com/mikf/gallery-dl

set -eu

log=~/.cache/coomer.log
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0"
domain='https://coomer.party'
tmpfile=$(mktemp)
end() {
    rm "$tmpfile" 2>/dev/null || true
}
trap end INT HUP EXIT

get_posts() { grep -oP '(?<=href\=\")/\w*/user/.*/post/\d*(?=")'; }
logging() { echo "[$(date '+%Y.%m.%d %H:%M:%S')][$user] $*" >> "$log"; }
main() {
    declare -x user
    main_url=$(echo "$1" | grep -oP 'https://coomer.party/\w*/user/[^/\?]*')
    test -z "$main_url" && { logging "invalid url: $1"; return 1; }
    user=$(echo "$1" | grep -oP '\w*/user/[^/$]*' | sed 's/.user//')
    DL_DIR=~/Downloads/coomer/"$user"
    [ -d "$DL_DIR" ] || mkdir -vp "${DL_DIR}"
    if [ -z "$max_page" ];then
        max_page=$(
            curl -A "$UA" -s "$main_url" | tee "$tmpfile" |
            grep -oP '(?<=href\=\")/\w*/user/\d.*[\?&]o=\d*(?=\")' |
            grep -oP '(?<=[\?&]o=)\d*' | sort -n | tail -1
        )
    fi
    # shellcheck disable=SC2086
    for page in $(seq ${start_page:-0} 25 ${max_page:-0});do
        logging "${main_url}?o=$page"
        if test -f "$tmpfile";then
            get_posts < "$tmpfile"
            rm "$tmpfile"
        else
            curl -A "$UA" -s "${main_url}?o=$page" | get_posts
        fi | while read -r url;do
            post_url="$domain$url"
            logging "post: $post_url"
            curl -A "$UA" -s "$post_url" -o "$tmpfile"
            dl_dir="${DL_DIR}/${url##*/}"
            [ -d "$dl_dir" ] || mkdir -vp "$dl_dir"

            grep -oP 'https://drive\.google\.com/[^ \t\n\"<]*' "$tmpfile" | sed 's/\.$//g' | sort -u | while read -r url
            do
                case "$url" in
                    *[\&\?]id=*) FILEID=$(echo "$url" | grep -oP '(?<=[\?&]id=)[^&$]*')    ;;
                    */folders/*) FILEID=$(echo "$url" | grep -oP '(?<=/folders/)[^\?$/]*') ;;
                    */file/d/*)  FILEID=$(echo "$url" | grep -oP '(?<=/file/d/)[^/\?$]*')  ;;
                esac
                test -z "$FILEID" && { logging "FILEID not found: $url"; continue; }
                logging "gdrive: $url"
                logging "FILEID: $FILEID"
                gdrive download --path "$dl_dir" --skip -r "$FILEID" || logging "gdrive download failed: $url"
                unset FILEID
            done

            grep -oP 'https://mega\.nz/[^ \t\n\"<]*' "$tmpfile" | sed 's/\.$//g' | sort -u | while read -r url
            do
                mega-get -q "$url" "$dl_dir" || { logging "mega download failed: $url"; continue; }
                logging "download completed: $url"
            done

            grep -oP 'https://gofile\.[^ \t\n\"<]*' "$tmpfile" | while read -r url
            do
                gallery-dl -d "$dl_dir" "$url" || { logging "gofile download failed: $url"; continue; }
                logging "download completed: $url"
            done

            grep -oP 'https://[^ \t\n\"<]*\.(mp4|webm|mov|m4v|7z|zip|rar)' "$tmpfile" | sed 's/\.$//g' | sort -u | while read -r url
            do
                case "$url" in
                    *giant.gfycat.com*) continue ;; # DEAD
                    *my.mixtape.moe*)   continue ;; # DEAD
                    *a.pomf.cat*)       continue ;; # DEAD
                    *dropbox.com*) yt-dlp "$url" ;;
                    *gofile*) gallery-dl -d "$dl_dir" "$url" ;;
                    *) wget -t 5 -w 5 -U "$UA" -nc -P "$dl_dir" "$url" ;;
                esac || { logging "download failed: $url"; continue; }
                logging "download completed: $url"
            done

            grep -oP '(?<=href\=\")/data/[^\"]*\.(mp4|webm|mov|m4v|7z|zip|rar|png|jpe?g|gif)' "$tmpfile" | while read -r url
            do
                logging "coomer data: $domain$url"
                echo "$domain$url"
            done | sort -u | aria2c -d "$dl_dir" -s 4 -j 2 --input-file=-

            rm "$tmpfile"
            rm -d "$dl_dir" 2>/dev/null || true
        done
    done
}
help() {
    printf 'Usage: %s [-m|--max-page <N> -p|--start-page <N>] <URL | FILE>\n' "${0##*/}"
    exit 0
}

urls=()
input_file=
max_page=
while (( $# ));do
    case "$1" in
        -m|--max-page) shift; [ "$1" -gt 1 ] && max_page="$1" ;;
        -p|--start-page) shift; [ "$1" -ge 0 ] && start_page="$1" ;;
        -h|--help) help ;; 
        http*) urls+=("$1") ;;
        *) [ -f "$1" ] && input_file="$1" ;;
    esac
    shift
done

if [ -f "$input_file" ]; then
    while read -r url; do
        main "$url"
    done < "$input_file"
elif [ "${#urls[@]}" -gt 0 ]; then
    for url in "${urls[@]}"; do
        main "$url"
    done
else
    help
fi
