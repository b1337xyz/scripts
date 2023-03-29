#!/usr/bin/env bash
# shellcheck disable=SC2086

# Dependencies:
#   https://github.com/meganz/MEGAcmd
#   https://github.com/prasmussen/gdrive
#   https://github.com/yt-dlp/yt-dlp
#   https://github.com/mikf/gallery-dl

UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0"

log=~/.cache/kemono.log
domain='https://kemono.party'
tmpfile=$(mktemp)
end() { rm "$tmpfile" 2>/dev/null; }
trap end EXIT

get_posts() { grep -oP '(?<=href\=")/\w*/user/\d*/post/[A-z0-9]*(?=")'; }
main() {
    main_url=$(echo "$1" | grep -oP 'https://kemono.party/\w*/user/\d*')
    test -z "$main_url" && return 1
    user=$(echo "$1" | grep -oP '\w*/user/\d*' | sed 's/.user//')
    DL_DIR=~/Downloads/kemono/"$user"
    [ -d "$DL_DIR" ] || mkdir -vp "${DL_DIR}"
    if [ -z "$max_page" ];then
        max_page=$(
            curl -A "$UA" -s "$main_url" | tee "$tmpfile" |
            grep -oP '(?<=href\=\")/\w*/user/\d.*[\?&]o=\d*(?=\")' |
            grep -oP '(?<=[\?&]o=)\d*' | sort -n | tail -1
        )
    fi
    echo "$main_url" >> "$log"

    # shellcheck disable=SC2086
    for page in $(seq ${start_page:-0} 25 ${max_page:-0});do
        if test -f "$tmpfile";then  # don't request the first page twice
            get_posts < "$tmpfile"
            rm "$tmpfile"
        else
            curl -A "$UA" -s "${main_url}?o=$page" | get_posts
        fi | while read -r url;do
            post_url=${domain}$url
            dl_dir=${DL_DIR}/${url##*/}
            html=${dl_dir}/html
            [ -d "$dl_dir" ] || mkdir -p "$dl_dir"
            [ -f "$html" ] || curl -A "$UA" -s "$post_url" -o "$html"

            # grep -ioP '(pw|password)[: ]?[^ \t\n<]*' "$html" | awk '{sub(/(password|pw)[ :]\?/ "")}'
            pw=$(grep -ioP '(pw|pass\w+) ?: ?[^ <]*' "$html" | sort -u)
            [ -z "$pw" ] && pw=$(grep -ioP 'password is ?:? ?[^ <]*' "$html" | sort -u)
            [ -n "$pw" ] && echo "$pw" >> "${dl_dir}/password"

            grep -oP 'https://drive\.google\.com/[^ \t\n\"<]*' "$html" | sed 's/\.$//g' | sort -u | while read -r url
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

            # grep -oP 'https://mega\.nz/[^ \t\n\"<]*' "$html" | sed 's/\.$//g' | sort -u | while read -r url
            # do
            #     mega-get -q "$url" "$dl_dir"
            # done

            grep -oP 'https://gofile\.[^ \t\n\"<]*' "$html" | sed 's/\.$//g' | sort -u | while read -r url
            do
                gallery-dl -d "$dl_dir" "$url"
            done

            grep -oP 'https://[^ \t\n\"<]*\.(mp4|webm|mov|m4v|7z|zip|rar)' "$html" | sed 's/\.$//g' | sort -u | while read -r url
            do
                case "$url" in
                    *giant.gfycat.com*) continue ;; # DEAD
                    *my.mixtape.moe*)   continue ;; # DEAD
                    *a.pomf.cat*)       continue ;; # DEAD
                    *.fanbox.cc*)       continue ;; # use https://github.com/Nandaka/PixivUtil2
                    # *dropbox*) wget --content-disposition -t 5 -w 5 -U "$UA" -nc -P "$dl_dir" "${url%\?*}?dl=1" ;;
                    *dropbox*) aria2c --dir "$dl_dir" "${url%\?*}?dl=1" ;;
                    *gofile*) gallery-dl -d "$dl_dir" "$url" ;;
                    *) aria2c --dir "$dl_dir" "$url" ;;
                esac
                # wget -t 5 -w 5 -U "$UA" -nc -P "$dl_dir" "$url"
            done

            grep -oP '(href|src)=\".*data/[^\"]*\.(mp4|webm|mov|m4v|7z|zip|rar|png|jpe?g|gif)' "$html" |
                grep -v thumbnail | cut -d \" -f2- | sort -u | while read -r url
            do
                case "$url" in
                    http*) aria2c --dir "$dl_dir" "$url" ;;
                    *data*) aria2c --dir "$dl_dir" "${domain}${url}" ;;
                esac
            done

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
