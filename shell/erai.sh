#!/usr/bin/env bash

command -v fzf &>/dev/null || { printf 'install fzf\n'; exit 1; }

declare -r -x domain="https://txt.erai-raws.org"
declare -r -x tmpfile=$(mktemp)
declare -r -x dlicon=folder-download
declare -r -x favicon=emblem-favorite-symbolic.symbolic
declare -r -x delicon=user-trash
declare -r -x cache=~/.cache/erai.txt

end() { rm "$tmpfile"; }
trap end EXIT

quote() {
    sed '
    s/%/%25/g;  s/ /%20/g;  s/\[/%5B/g;
    s/\]/%5D/g; s/</%3C/g;  s/>/%3E/g;
    s/#/%23/g;  s/{/%7B/g;  s/}/%7D/g;
    s/|/%7C/g;  s/\\/%5C/g; s/\^/%5E/g;
    s/~/%7E/g;  s/`/%60/g;  s/\;/%3B/g;
    s/?/%3F/g;  s/@/%40/g;  s/=/%3D/g;
    s/&/%26/g;  s/\$/%24/g'
}
unquote() {
    sed '
    s/%25/%/g;  s/%20/ /g;  s/%5B/\[/g;
    s/%5D/\]/g; s/%3C/</g;  s/%3E/>/g;
    s/%23/#/g;  s/%7B/{/g;  s/%7D/}/g;
    s/%7C/|/g;  s/%5C/\\/g; s/%5E/\^/g;
    s/%7E/~/g;  s/%60/`/g;  s/%3B/\;/g;
    s/%3F/?/g;  s/%40/@/g;  s/%3D/=/g;
    s/%26/&/g;  s/%24/\$/g'
}
main() {
    if [[ "${1##*.}" =~ (ass|srt) ]];then
        dir=${1##*dir=}
        dir=${dir%/*}
        dldir="${HOME}/Downloads/"
        mkdir -p "$dldir"
        for i in "$@";do
            f=$(echo "${i##*/}" | unquote)
            if ! [ -f "${dldir}/${f}" ];then
                notify-send -i "$dlicon" "Erai Sub Downloader" "$f"
                wget -nc -q -P "$dldir" "${domain}/$i"
            fi
        done
    elif [[ "$1" =~ ^http ]];then
        url="$1"
    else
        dir=$(echo ${1##*dir=} | quote)
        url="${domain}/?dir=${dir}"
    fi
    [ -n "$url" ] &&
        curl -s "$url" | awk '/<div id="content"/,EOF {print $0}' > "$tmpfile"

    {
        grep -ioP '(?<=href\=")Sub/.*\.(ass|srt)(?=")' "$tmpfile";
        grep -oP '(?<=href\="\?dir\=)Sub[^"]*' "$tmpfile";
    } | unquote | sort
}
favorite() {
    if ! grep -qF "$1" "$cache" 2>/dev/null;then
        notify-send -i "$favicon" "Erai Sub Downloader" "$1"
        echo "$1" >> "$cache";
    else
        notify-send -i "$delicon" "Erai Sub Downloader" "$1"
        n=$(grep -nF "$1" "$cache" | cut -d':' -f1)
        sed -i "${n}d" "$cache"
    fi
}
export -f main unquote quote favorite
case "$1" in
    -l|--load)
        [ -s "$cache" ] || exit 1
        cat "$cache"
    ;;
    [0-9]*)     main "Sub/${1}"     ;;
    *)          main "${1:-Sub}"    ;;
esac | fzf -m --header '^f favorite'    \
    --bind 'ctrl-t:last'                \
    --bind 'ctrl-b:first'               \
    --bind 'enter:reload(main {+})'     \
    --bind 'ctrl-f:execute(favorite {})'
