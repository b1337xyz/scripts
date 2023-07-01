#!/usr/bin/env bash
# Dependencies:
#   https://github.com/meganz/MEGAcmd
#   https://github.com/prasmussen/gdrive
#   https://github.com/yt-dlp/yt-dlp
#   https://github.com/mikf/gallery-dl

UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0"
BASE_DIR=~/Downloads/kemono
DOMAIN='https://kemono.party'
log=~/.cache/kemono.log
tmpfile=$(mktemp)
end() { rm "$tmpfile" 2>/dev/null; }
trap end EXIT

a2c() {
    printf '%s -> %s\n' "$2" "$1"
    aria2c --summary-interval=0 --auto-file-renaming=false --dir "$1" "$2"
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

grep_dropbox() {
    grep -oP 'https://(www\.)?dropbox\.[^\"]*' "$1" | sed 's/\([&?]\)dl=0/\1dl=1/'
}

grep_file_links() {
    grep -oP 'https://[^ \t\n\"<]*\.(mp4|webm|mov|m4v|7z|zip|rar)' "$1" | sort -u
}

grep_data_links() {
    grep -oP '(href|src)=\".*data/[^\"]*\.(mp4|webm|mov|m4v|7z|zip|rar|png|jpe?g|gif)' "$1" | grep -v thumbnail | cut -d \" -f2-
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

skip() {
    [[ "$1" =~ $2 ]] && printf 'Skipping: %s\n' "$1"
}

download_post_content() {
    dl_dir=$2
    html=${dl_dir}/html
    [ -d "$dl_dir" ] || mkdir -vp "$dl_dir"
    [ -f "$1" ] && mv -v "$1" "$html"
    [ -f "$html" ] || curl -A "$UA" -s "$1" -o "$html"

    pub=$(grep -oP '(?<=meta name="published" content=")[^ ]*' "$html")
    title=$(grep -oP '(?<=meta property="og:title" content="&#34;).*(?=&#34;)' "$html" |
            sed 's/\// /g; s/ \{2,\}/ /g' | unescape)

    dl_dir="${dl_dir}/${title} ${pub}"
    mkdir -vp "$dl_dir"

    # grep -ioP '(pw|password)[: ]?[^ \t\n<]*' "$html" | awk '{sub(/(password|pw)[ :]\?/ "")}'
    pw=$(grep -ioP '(pw|pass\w+) ?: ?[^ <]*' "$html" | sort -u)
    [ -z "$pw" ] && pw=$(grep -ioP 'password is ?:? ?[^ <]*' "$html" | sort -u)
    [ -n "$pw" ] && printf '%s\n' "$pw" >> "${dl_dir}/password"

    grep_gd "$html" | while read -r url
    do
        [ "$OUTPUT" ] && { printf '%s\n' "$url" >> "$OUTPUT"; continue; }
        case "$url" in
            *[\&\?]id=*) FILEID=$(echo "$url" | grep -oP '(?<=[\?&]id=)[^&$]*')    ;;
            */folders/*) FILEID=$(echo "$url" | grep -oP '(?<=/folders/)[^\?$/]*') ;;
            */file/d/*)  FILEID=$(echo "$url" | grep -oP '(?<=/file/d/)[^/\?$]*')  ;;
        esac
        test -z "$FILEID" && continue
        gdrive download --path "$dl_dir" --skip -r "$FILEID"
        unset FILEID
    done

    grep_mega "$html" | while read -r url
    do
        [ "$OUTPUT" ] && { printf '%s\n' "$url" >> "$OUTPUT"; continue; }
        # mega-get "$url" "$dl_dir"
    done

    grep_dropbox "$html" | while read -r url
    do
        [ "$OUTPUT" ] && { printf '%s\n' "$url" >> "$OUTPUT"; continue; }
        a2c "$dl_dir" "$url"
    done

    grep_file_links "$html" | while read -r url
    do
        [ "$OUTPUT" ] && { printf '%s\n' "$url" >> "$OUTPUT"; continue; }
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
        [ "$OUTPUT" ] && { printf '%s\n' "$url" >> "$OUTPUT"; continue; }
        case "$url" in
            http*)  printf '%s\n' "$url" ;;
            *data*) printf '%s\n' "${DOMAIN}${url}" ;;
        esac
    done | sort -u | aria2c -j 1 --auto-file-renaming=false \
        --summary-interval=0 --dir "$dl_dir" --input-file=-
}

main() {
    if [[ "$1" = */post/* ]];then
        curl -A "$UA" -s -o "$tmpfile" "$1"
        user=$(grep_user "$tmpfile")
        artist=$(grep_artist "$tmpfile")
        download_post_content "$tmpfile" "${BASE_DIR}/${user} - ${artist}"
        return
    fi

    main_url=$(printf '%s' "$1" | grep -oP 'https://kemono.party/\w*/user/\d*')
    test -z "$main_url" && return 1
    curl -A "$UA" -s "$main_url" -o "$tmpfile"

    [ -z "$max_page" ] && max_page=$(
        grep -oP '(?<=href\=\")/.*/user/.*[\?&]o=\d*(?=\")' "$tmpfile" |
            grep -oP '(?<=[\?&]o=)\d*' | sort -n | tail -1;
    )
    echo "$main_url" >> "$log"
    user=$(grep_user "$tmpfile")
    artist=$(grep_artist "$tmpfile")

    # shellcheck disable=SC2086
    for page in $(seq ${start_page:-0} 25 ${max_page:-0});do
        if test -f "$tmpfile";then  # don't request the first page twice
            grep_posts < "$tmpfile"
            rm "$tmpfile"
        else
            curl -A "$UA" -s "${main_url}?o=$page" | grep_posts
        fi | while read -r url;do
            post_url=${DOMAIN}$url
            download_post_content "$post_url" "${BASE_DIR}/${user} - ${artist}"
        done
    done
}
help() {
    printf 'Usage: %s [-o|--output <FILE> -m|--max-page <N> -p|--start-page <N>] <URL | FILE>\n' "${0##*/}"
    exit 0
}

urls=()
input_file=
max_page=
while (( $# ));do
    case "$1" in
        -o|--output) shift; OUTPUT="$1" ;;
        -m|--max-page) shift; [ "$1" -ge 0 ] && max_page="$1" ;;
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
fi
