#!/usr/bin/env bash
# Dependencies:
#   https://github.com/meganz/MEGAcmd
#   https://github.com/prasmussen/gdrive
#   https://github.com/yt-dlp/yt-dlp
#   https://github.com/mikf/gallery-dl

# set -e

UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0"
BASE_DIR=~/Downloads/kemono
DOMAIN='https://kemono.su'
tmpfile=$(mktemp)
end() { rm "${tmpfile}" "${tmpfile}.posts" 2>/dev/null || true; }
trap end EXIT

a2c() {
    aria2c -q --auto-file-renaming=false --dir "$1" "$2" || printf '\e[1;31mDownload failed %s, %s\e[m\n' "$1" "$2"
}

grep_posts() {
    grep -oP '(?<=href\=")/.*/user/.*/post/[^\"]*'
}

grep_gd() {
    [ "$SKIP_GDRIVE" = y ] && return
    grep -oP 'https://drive\.google\.com/[^ \t\n\"<]*' "$1" | sed 's/\.$//g' | sort -u
}

grep_mega() {
    [ "$SKIP_MEGA" = y ] && return
    grep -oP 'https://mega\.\w+/[^ \t\n\"<]*' "$1" | sed 's/\.$//g' | sort -u
}

grep_dropbox() {
    [ "$SKIP_DROPBOX" = y ] && return
    grep -oP 'https://(www\.)?dropbox\.[^\"]*' "$1" | sed 's/\([&?]\)dl=0/\1dl=1/'
}

grep_data_links() {
    [ "$SKIP_DATA" = y ] && return
    grep -oP '(href|src)=\".*data/[^\"]*\.(mp4|webm|mov|m4v|7z|zip|rar|png|jpe?g|gif)' "$1" | grep -v thumbnail | cut -d \" -f2-
}

grep_file_links() {
    [ "$SKIP_FILES" = y ] && return
    grep -oP 'https://[^ \t\n\"<]*\.(mp4|webm|mov|m4v|7z|zip|rar)' "$1" | sort -u
}

grep_artist() {
    if ! grep -oP '(?<=meta name="artist_name" content=").*(?=">)' "$1" ;then
        tr -d \\n < "$1" | grep -oP 'post__user-name[^<]*' | sed -E 's/ +$//; s/.*> +(.*)/\1/'
    fi
}

grep_user() {
    if ! grep -oP '(?<=meta name="user" content=").*(?=">)' "$1"; then
        grep -oP '(?<=meta name="id" content=").*(?=">)' "$1"
    fi
}

unescape() {
    python3 -c 'print(__import__("html").unescape(("\n".join(__import__("sys").stdin).strip())))'
}

unquote() {
    python3 -c 'print(__import__("urllib.parse").parse.unquote(("\n".join(__import__("sys").stdin).strip())))'
}

download_post_content() {
    dl_dir=$2
    html=${dl_dir}/html
    [ -d "$dl_dir" ] || mkdir -p "$dl_dir"
    if [ -f "$1" ]; then
        mv -v "$1" "$html"
    else
        curl -A "$UA" -s "$1" -o "$html"
    fi

    pub=$(grep -oP '(?<=meta name="published" content=")[^ ]*' "$html")
    title=$(grep -oP '(?<=meta property="og:title" content="&#34;).*(?=&#34;)' "$html" |
            sed 's/\// /g; s/ \{2,\}/ /g' | unescape)

    dl_dir="${dl_dir}/${pub} ${title}"
    mkdir -p "$dl_dir"

    # grep -ioP '(pw|password)[: ]?[^ \t\n<]*' "$html" | awk '{sub(/(password|pw)[ :]\?/ "")}'
    pw=$(grep -ioP '(pw|pass\w+) ?: ?[^ <]*' "$html" | sort -u)
    [ -z "$pw" ] && pw=$(grep -ioP 'password is ?:? ?[^ <]*' "$html" | sort -u)
    [ -n "$pw" ] && printf '\e[1;31m%s\e[m\n' "$pw" >> "${dl_dir}/password"

    grep_gd "$html" | while read -r url
    do
        case "$url" in
            *[\&\?]id=*) FILEID=$(grep -oP '(?<=[\?&]id=)[^&$]*' <<< "$url")    ;;
            */folders/*) FILEID=$(grep -oP '(?<=/folders/)[^\?$/]*' <<< "$url") ;;
            */file/d/*)  FILEID=$(grep -oP '(?<=/file/d/)[^/\?$]*' <<< "$url")  ;;
        esac
        test -z "$FILEID" && continue
        gdrive files download --destination "$dl_dir" --recursive "$FILEID" || true
        unset FILEID
    done

    grep_mega "$html" | while read -r url
    do
        mega-get "$url" "$dl_dir"
    done

    grep_dropbox "$html" | while read -r url
    do
        a2c "$dl_dir" "$url"
    done

    grep_file_links "$html" | while read -r url
    do
        case "$url" in
            *giant.gfycat.com*) continue ;; # DEAD
            *my.mixtape.moe*)   continue ;; # DEAD
            *a.pomf.cat*)       continue ;; # DEAD
            *fanbox.cc*)        continue ;;
            *dropbox*) a2c "$dl_dir" "${url%\?*}?dl=1" ;;
            *) a2c "$dl_dir" "$url" ;;
        esac
    done

    grep_data_links "$html" | while read -r url
    do
        case "$url" in
            http*)  printf '%s\n' "$url" ;;
            *data*) printf '%s\n' "${DOMAIN}${url}" ;;
        esac
    done | sort -u | aria2c -q -j 1 --auto-file-renaming=false --dir "$dl_dir" --input-file=-
}

main() {
    if [[ "$1" = */post/* ]];then
        curl -A "$UA" -s -o "$tmpfile" "$1"
        user=$(grep_user "$tmpfile")
        artist=$(grep_artist "$tmpfile")
        download_post_content "$tmpfile" "${BASE_DIR}/${user} - ${artist}"
        return
    fi

    main_url=$(printf '%s' "$1" | grep -oP 'https://kemono.(party|su)/\w*/user/\d*')
    test -z "$main_url" && return 1
    curl -A "$UA" -s "$main_url" -o "$tmpfile"

    [ -z "$max_page" ] && max_page=$(
        grep -oP '(?<=href\=\")/.*/user/.*[\?&]o=\d*(?=\")' "$tmpfile" |
            grep -oP '(?<=[\?&]o=)\d*' | sort -n | tail -1;
    )
    user=$(grep_user "$tmpfile")
    artist=$(grep_artist "$tmpfile")

    post_counter=0
    total_posts=0
    # shellcheck disable=SC2086
    for page in $(seq ${start_page:-0} 25 ${max_page:-0});do
        if test -f "$tmpfile";then
            grep_posts < "$tmpfile"
            rm "$tmpfile"
        else
            curl -A "$UA" -s "${main_url}?o=$page" | grep_posts
        fi > "${tmpfile}.posts"

        l_posts=$(wc -l < "${tmpfile}.posts")
        total_posts=$((total_posts + l_posts))
        while read -r url; do
            post_counter=$((post_counter+1))
            [ "$max_posts" ] && [[ "$post_counter" -gt "$max_posts" ]] && return
            printf '\e[1;32m[%s/%s] %s\e[m\n' "$post_counter" "$total_posts" "$artist"
            post_url=${DOMAIN}$url
            download_post_content "$post_url" "${BASE_DIR}/${user} - ${artist}"
        done < "${tmpfile}.posts"
    done
}

help() {
    cat << EOF
Usage: ${0##*/} [-mPp --skip-*] URL|FILE

    -m --max-page N     max pages to scrape
    -P --max-posts N    max posts to scrape
    -p --start-page N   start from page N
    --skip-mega         don't grep mega links
    --skip-dropbox      don't grep dropbox links
    --skip-gdrive       don't grep gdrive links
    --skip-data         don't grep /data/*.(mp4|webm|m4v|png...) links
    --skip-files        don't grep http*.(mp4|webm|m4v|png...) links
EOF
    exit 0
}

urls=()
while (( $# ));do
    case "$1" in
        -P|--max-posts) shift; [ "$1" -ge 0 ] && max_posts="$1" ;;
        -m|--max-page) shift; [ "$1" -ge 0 ] && max_page="$1" ;;
        -p|--start-page) shift; [ "$1" -ge 0 ] && start_page="$1" ;;
        -h|--help) help ;; 
        --skip-data) SKIP_DATA=y ;;
        --skip-mega) SKIP_MEGA=y ;;
        --skip-dropbox) SKIP_DROPBOX=y ;;
        --skip-gdrive) SKIP_GDRIVE=y ;;
        --skip-files) SKIP_FILES=y ;;
        http*) urls+=("$1") ;;
        *) [ -f "$1" ] && input_file="$1" ;;
    esac
    shift
done

set -x

if [ -f "$input_file" ]; then
    while read -r url; do
        main "$url"
    done < "$input_file"
elif [ "${#urls[@]}" -gt 0 ]; then
    for url in "${urls[@]}"; do
        main "$url"
    done
fi
