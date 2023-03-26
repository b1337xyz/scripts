#!/usr/bin/env bash
# shellcheck disable=SC2086

# Dependencies:
#   https://github.com/meganz/MEGAcmd
#   https://github.com/prasmussen/gdrive
#   https://github.com/yt-dlp/yt-dlp
#   https://github.com/mikf/gallery-dl

UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0"
domain='https://kemono.party'
tmpfile=$(mktemp)

downloading() {
    active=$(curl -s 'http://localhost:6802/jsonrpc' \
        --data '{"id":"1", "method":"aria2.tellActive"}' | jq -Mc '.result')
    waiting=$(curl -s 'http://localhost:6802/jsonrpc' \
        --data '{"id":"1", "method":"aria2.tellWaiting", "params":[0,1]}}' | jq -Mc '.result')

    [ "$active" != "[]" ] && [ "$waiting" != "[]" ]
}
end() {
    rm "$tmpfile" 2>/dev/null
    while downloading ;do sleep 5 ;done
    pkill -f 'aria2c -D --enable-rpc --rpc-listen-port 6802'
}
trap end EXIT

aria2c -D --enable-rpc --rpc-listen-port 6802 -j 1 --continue || exit 1

addUri() {
    data=$(printf '{"jsonrpc":"2.0", "id":"1", "method":"aria2.addUri", "params":[["%s"], {"dir": "%s"}]}' "$1" "$2")
    curl -s "http://localhost:6802/jsonrpc" \
        -H "Content-Type: application/json" -H "Accept: application/json" \
        -d "$data" #>/dev/null 2>&1
    printf '%s -> %s\n' "${1##*/}" "$2"
}
get_posts() { grep -oP '(?<=href\=")/\w*/user/\d*/post/[A-z0-9]*(?=")'; }
main() {
    declare -x user
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
    echo "$main_url" >> ~/.cache/kemono.log

    # shellcheck disable=SC2086
    for page in $(seq ${start_page:-0} 25 ${max_page:-0});do
        if test -f "$tmpfile";then
            get_posts < "$tmpfile"
            rm "$tmpfile"
        else
            curl -A "$UA" -s "${main_url}?o=$page" | get_posts
        fi | while read -r url;do
            post_url="$domain$url"
            dl_dir=${DL_DIR}/${url##*/}
            html=${dl_dir}/html
            [ -d "$dl_dir" ] || mkdir -p "$dl_dir"
            [ -f "$html" ] || curl -A "$UA" -s "$post_url" -o "$html"

            # grep -ioP '(pw|password)[: ]?[^ \t\n<]*' "$html" | awk '{sub(/(password|pw)[ :]\?/ "")}'
            pw=$(grep -ioP '(pw|pass\w+) ?: ?[^ <]*' "$html" | sort -u)
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

            grep -oP 'https://mega\.nz/[^ \t\n\"<]*' "$html" | sed 's/\.$//g' | sort -u | while read -r url
            do
                mega-get -q "$url" "$dl_dir"
            done

            grep -oP 'https://gofile\.[^ \t\n\"<]*' "$html" | sed 's/\.$//g' | sort -u | while read -r url
            do
                gallery-dl -d "$dl_dir" "$url"
            done

            grep -ioP 'https://[^ \t\n\"<]*\.(mp4|webm|mov|m4v|7z|zip|rar)' "$html" |
            sed 's/\.$//g' | sort -u | while read -r url
            do
                case "$url" in
                    *giant.gfycat.com*) continue ;; # DEAD
                    *my.mixtape.moe*)   continue ;; # DEAD
                    *a.pomf.cat*)       continue ;; # DEAD
                    *.fanbox.cc*)       continue ;; # use https://github.com/Nandaka/PixivUtil2
                    # *dropbox*) yt-dlp "$url" ;;
                    # *dropbox*) wget --content-disposition -t 5 -w 5 -U "$UA" -nc -P "$dl_dir" "${url%\?*}?dl=1" ;;
                    *dropbox*) addUri "${url%\?*}?dl=1" "$dl_dir" ;;
                    *gofile*) gallery-dl -d "$dl_dir" "$url" ;;
                    *) addUri "$url" "$dl_dir" ;;
                esac
                # wget -t 5 -w 5 -U "$UA" -nc -P "$dl_dir" "$url"
            done

            grep -oiP '(?<=\=\").*data/[^\"]*\.(mp4|webm|mov|m4v|7z|zip|rar|png|jpe?g|gif)' "$html" |
            grep -v thumbnail | sort -u | while read -r url
            do
                case "$url" in
                    http*) addUri "$url" "$dl_dir" ;;
                    *data*) addUri "${domain}${url}" "$dl_dir" ;;
                esac
            done
            # done | aria2c -d "$dl_dir" -s 4 -j 2 --input-file=- || true
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
