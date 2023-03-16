#!/usr/bin/env bash
# shellcheck disable=SC2317
declare -r -x DLDIR=~/Downloads
declare -r -x domain="https://txt.erai-raws.org"
declare -r -x icon=folder-download
declare -r -x favorites=~/.cache/erai.txt
declare -r -x cache_dir=/tmp/erai

end() { find "$cache_dir" -name 'tmp.html' -delete; }
trap end EXIT

quote() {
    python3 -c 'print(__import__("urllib.parse").parse.quote(("\n".join(__import__("sys").stdin).strip())))'
}
unquote() {
    python3 -c 'print(__import__("urllib.parse").parse.unquote(("\n".join(__import__("sys").stdin).strip())))'
}
download() {
    for i in "$@";do
        f=$(echo -n "${i##*/}" | unquote)
        if ! [ -f "${DLDIR}/${f}" ];then
            wget -nc -q -P "$DLDIR" "${domain}/$i"
            notify-send -i "$icon" "Erai Sub Downloader" "$f downloading..."
        fi
    done
}
main() {
    local url dir
    dir=$(printf '%s' "${1##*dir=}" | quote)
    if [[ "${1##*.}" =~ (ass|srt) ]];then
        download "$@"
        dir=${dir%/*}
    elif [[ "$1" =~ ^http ]];then
        url="$1"
    else
        url="${domain}/?dir=${dir}"
    fi

    html="${cache_dir}/${dir}/tmp.html"
    if ! [ -f "$html" ];then
        mkdir -p "${html%/*}"
        curl -s "$url" |
        awk '/<div id="content"/,EOF {print $0}' > "$html"
    fi

    {
        grep -ioP '(?<=href\=")Sub/.*\.(ass|srt)' "$html";
        grep -oP '(?<=href\="\?dir\=)Sub[^"]*' "$html";
    } | unquote | grep . | sort -u
}

favorite() {
    if ! grep -qF "$1" "$favorites" 2>/dev/null;then
        notify-send "Erai Sub Downloader" "$1 added"
        echo "$1" >> "$favorites";
    else
        notify-send "Erai Sub Downloader" "$1 removed"
        n=$(grep -nF "$1" "$favorites" | cut -d':' -f1)
        sed -i "${n}d" "$favorites"
    fi
}
export -f main unquote quote favorite download 
case "$1" in
    -f|--favorites)
        [ -s "$favorites" ] || exit 1
        cat "$favorites"
    ;;
    -r|--release)
        q=$(date +%q)
        y=$(date +%Y)
        case "$q" in
            1) s=Winter ;;
            2) s=Spring ;;
            3) s=Summer ;;
            4) s=Fall ;;
        esac
        main "Sub/$y/$s"
    ;;
    [0-9]*)     main "Sub/${1}"     ;;
    *)          main "${1:-Sub}"    ;;
esac | fzf --no-info --tac --reverse --height 25 -m \
    --bind 'ctrl-t:last'  \
    --bind 'ctrl-b:first' \
    --bind 'enter:reload(main {+})+clear-query' \
    --bind 'ctrl-f:execute(favorite {})'

exit 0
