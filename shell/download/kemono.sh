#!/usr/bin/env bash
# shellcheck disable=SC2086

# Dependencies:
#   https://github.com/meganz/MEGAcmd
#   https://github.com/prasmussen/gdrive
#   https://github.com/yt-dlp/yt-dlp
#   https://github.com/mikf/gallery-dl

UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0"
DOMAIN='https://kemono.party'
log=~/.cache/kemono.log
tmpfile=$(mktemp)
end() { rm "$tmpfile" 2>/dev/null; }
trap end EXIT

a2c() {
    aria2c --auto-file-renaming=false --dir "$1" "$2"
}

grep_posts() {
    grep -oP '(?<=href\=")/.*/user/.*/post/[^\"]*'
}

grep_gd() {
    grep -oP 'https://drive\.google\.com/[^ \t\n\"<]*' "$1" | sed 's/\.$//g' | sort -u
}

grep_mega() {
    grep -oP 'https://mega\.nz/[^ \t\n\"<]*' "$1" | sed 's/\.$//g' | sort -u
}

grep_file_links() {
    grep -oP 'https://[^ \t\n\"<]*\.(mp4|webm|mov|m4v|7z|zip|rar)' "$1" | sort -u
}

grep_data_links() {
    grep -oP '(href|src)=\".*data/[^\"]*\.(mp4|webm|mov|m4v|7z|zip|rar|png|jpe?g|gif)' "$1" | grep -v thumbnail | cut -d \" -f2-
}

download_post_content() {
    dl_dir=${DL_DIR}/${1##*/}
    html=${dl_dir}/html
    [ -d "$dl_dir" ] || mkdir -p "$dl_dir"
    [ -f "$html" ] || curl -A "$UA" -s "$1" -o "$html"

    # grep -ioP '(pw|password)[: ]?[^ \t\n<]*' "$html" | awk '{sub(/(password|pw)[ :]\?/ "")}'
    pw=$(grep -ioP '(pw|pass\w+) ?: ?[^ <]*' "$html" | sort -u)
    [ -z "$pw" ] && pw=$(grep -ioP 'password is ?:? ?[^ <]*' "$html" | sort -u)
    [ -n "$pw" ] && printf '%s\n' "$pw" >> "${dl_dir}/password"

    grep_gd "$html" | while read -r url
    do
        case "$url" in
            *[\&\?]id=*) FILEID=$(echo "$url" | grep -oP '(?<=[\?&]id=)[^&$]*')    ;;
            */folders/*) FILEID=$(echo "$url" | grep -oP '(?<=/folders/)[^\?$/]*') ;;
            */file/d/*)  FILEID=$(echo "$url" | grep -oP '(?<=/file/d/)[^/\?$]*')  ;;
        esac
        test -z "$FILEID" && continue
        gdrive download --path "$dl_dir" --skip -r "$FILEID"
        unset FILEID
    done

    # grep_mega "$html" | while read -r url
    # do
    #     mega-get "$url" "$dl_dir"
    # done

    grep_file_links "$html" | while read -r url
    do
        case "$url" in
            *giant.gfycat.com*) continue ;; # DEAD
            *my.mixtape.moe*)   continue ;; # DEAD
            *a.pomf.cat*)       continue ;; # DEAD
            *dropbox*) a2c "$dl_dir" "${url%\?*}?dl=1" ;;
            *) a2c "$dl_dir" "$url" ;;
        esac
    done

    grep_data_links "$html" | while read -r url
    do
        case "$url" in
            http*) echo "$url" ;;
            *data*) echo "${DOMAIN}${url}" ;;
        esac
    done | sort -u | aria2c -j 1 --auto-file-renaming=false --dir "$dl_dir" --input-file=-

    rm -d "$dl_dir" 2>/dev/null || true
}

main() {
    main_url=$(printf '%s' "$1" | grep -oP 'https://kemono.party/\w*/user/\d*')
    test -z "$main_url" && return 1
    if [ -z "$max_page" ];then
        max_page=$(
            curl -A "$UA" -s "$main_url" | tee "$tmpfile" |
            grep -oP '(?<=href\=\")/.*/user/.*[\?&]o=\d*(?=\")' |
            grep -oP '(?<=[\?&]o=)\d*' | sort -n | tail -1
        )
    fi
    echo "$main_url" >> "$log"
    user=$(printf '%s' "$1" | grep -oP '\w*/user/\d*' | sed 's/.user//')
    artist=$(grep -oP '(?<=meta name="artist_name" content=").*(?=">)' "$tmpfile")
    DL_DIR=~/Downloads/kemono/"$user - $artist"
    [ -d "$DL_DIR" ] || mkdir -vp "${DL_DIR}"

    # shellcheck disable=SC2086
    for page in $(seq ${start_page:-0} 25 ${max_page:-0});do
        printf 'Post %s of %s\n' "$page" "${max_page:-1}" >&2
        if test -f "$tmpfile";then  # don't request the first page twice
            grep_posts < "$tmpfile"
            rm "$tmpfile"
        else
            curl -A "$UA" -s "${main_url}?o=$page" | grep_posts
        fi | while read -r url;do
            post_url=${DOMAIN}$url
            download_post_content "$post_url"
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
