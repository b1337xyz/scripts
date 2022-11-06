#!/usr/bin/env bash
# shellcheck disable=SC2086
# grep -oP '(?<=kemono data: ).*' "$log" | sort -u | aria2c -d "$dl_dir" -s 4 -j 2 --input-file=-

# Dependencies:
#   https://github.com/meganz/MEGAcmd
#   https://github.com/prasmussen/gdrive
#   https://github.com/yt-dlp/yt-dlp
#   https://github.com/mikf/gallery-dl

set -eu

START=0
JUST_THE_FIRST_PAGE=y

log=~/.cache/kemono.log
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0"
domain='https://kemono.party'
tmpfile=$(mktemp)
trap 'rm "$tmpfile" 2>/dev/null' INT HUP EXIT

get_posts() { grep -oP '(?<=href\=")/\w*/user/\d*/post/[A-z0-9]*(?=")'; }
logging() { echo "[$(date '+%Y.%m.%d %H:%M:%S')][$user] $*" >> "$log"; }
main() {
    main_url=$(echo "$1" | grep -oP 'https://kemono.party/\w*/user/\d*')
    test -z "$main_url" && { logging "invalid url: $1"; return 1; }
    user=$(echo "$1" | grep -oP '\w*/user/\d*' | sed 's/.user//')
    DL_DIR=~/Downloads/kemono/"$user"
    [ -d "$DL_DIR" ] || mkdir -vp "${DL_DIR}"
    max_page=$(
        curl -A "$UA" -s "$main_url" | tee "$tmpfile" |
        grep -oP '(?<=href\=\")/\w*/user/\d.*[\?&]o=\d*(?=\")' |
        grep -oP '(?<=[\?&]o=)\d*' | sort -n | tail -1
    )
    for page in $(seq $START 25 ${max_page:-0});do
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

            # grep -oP 'https://mega\.nz/[^ \t\n\"<]*' "$tmpfile" | sed 's/\.$//g' | sort -u | while read -r url
            # do
            #     mega-get -q "$url" "$dl_dir" || { logging "mega download failed: $url"; continue; }
            #     logging "download completed: $url"
            # done

            grep -oP 'https://gofile\.[^ \t\n\"<]*' "$tmpfile" | sed 's/\.$//g' | sort -u | while read -r url
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
                    *.fanbox.cc*)       continue ;; # use https://github.com/Nandaka/PixivUtil2
                    *dropbox.com*) yt-dlp "$url" ;;
                    *gofile*) gallery-dl -d "$dl_dir" "$url" ;;
                    *) wget -t 5 -w 5 -U "$UA" -nc -P "$dl_dir" "$url" ;;
                esac || { logging "download failed: $url"; continue; }
                logging "download completed: $url"
            done

            grep -oP '(?<=href\=\")/data/[^\"]*\.(mp4|webm|mov|m4v|7z|zip|rar|png|jpe?g|gif)' "$tmpfile" | while read -r url
            do
                logging "kemono data: $domain$url"
                echo "$domain$url"
            done | sort -u | aria2c -d "$dl_dir" -s 4 -j 2 --input-file=- || true

            rm "$tmpfile"
            rm -d "$dl_dir" 2>/dev/null || true
        done
        [ "$JUST_THE_FIRST_PAGE" = "y" ] && break
    done
}

if [ -f "$1" ];then
    while read -r i;do main "$i" ;done < "$1"
elif [ -n "$1" ];then
    main "$1"
fi
