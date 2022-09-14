#!/usr/bin/env bash
declare -r -x DLDIR=~/Downloads
declare -r -x domain="https://txt.erai-raws.org"
declare -r -x dlicon=folder-download
declare -r -x favicon=emblem-favorite-symbolic.symbolic
declare -r -x delicon=user-trash
declare -r -x favorites=~/.cache/erai.txt
declare -r -x tmpfile=$(mktemp)

end() { rm "$tmpfile"; }
trap end EXIT

quote() {
    sed '
    s/%/%25/g;    s/ /%20/g;    s/\[/%5B/g;
    s/\]/%5D/g;   s/</%3C/g;    s/>/%3E/g;
    s/#/%23/g;    s/{/%7B/g;    s/}/%7D/g;
    s/|/%7C/g;    s/\\/%5C/g;   s/\^/%5E/g;
    s/~/%7E/g;    s/`/%60/g;    s/\;/%3B/g;
    s/?/%3F/g;    s/@/%40/g;    s/=/%3D/g;
    s/&/%26/g;    s/\$/%24/g;   s/(/%28/g;
    s/)/%29/g;    s/!/%21/g;    s/Δ/%CE%94/g
    '
}
unquote() {
    sed '
    s/%25/%/g;    s/%20/ /g;    s/%5B/\[/g;
    s/%5D/\]/g;   s/%3C/</g;    s/%3E/>/g;
    s/%23/#/g;    s/%7B/{/g;    s/%7D/}/g;
    s/%7C/|/g;    s/%5C/\\/g;   s/%5E/\^/g;
    s/%7E/~/g;    s/%60/`/g;    s/%3B/\;/g;
    s/%3F/?/g;    s/%40/@/g;    s/%3D/=/g;
    s/%26/&/g;    s/%24/\$/g;   s/%28/(/g;
    s/%29/)/g;    s/%21/!/g;    s/%CE%94/Δ/g
    '
}
download() {
    for i in "$@";do
        f=$(echo "${i##*/}" | unquote)
        if ! [ -f "${DLDIR}/${f}" ];then
            wget -nc -q -P "$DLDIR" "${domain}/$i"
            notify-send -i "$dlicon" "Erai Sub Downloader" "$f"
        fi
    done
}
main() {
    local url dir
    if [[ "${1##*.}" =~ (ass|srt) ]];then
        download "$@"
    elif [[ "$1" =~ ^http ]];then
        url="$1"
    else
        dir=$(echo ${1##*dir=} | quote)
        url="${domain}/?dir=${dir}"
    fi

    if [ -n "$url" ];then
        curl -s "$url" |
        awk '/<div id="content"/,EOF {print $0}' > "$tmpfile"
    fi

    {
        grep -ioP '(?<=href\=")Sub/.*\.(ass|srt)' "$tmpfile";
        grep -oP '(?<=href\="\?dir\=)Sub[^"]*' "$tmpfile";
    } | unquote | sort
}

favorite() {
    if ! grep -qF "$1" "$favorites" 2>/dev/null;then
        notify-send -i "$favicon" "Erai Sub Downloader" "$1"
        echo "$1" >> "$favorites";
    else
        notify-send -i "$delicon" "Erai Sub Downloader" "$1"
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
esac | fzf -m --header '^f favorite' \
    --bind 'ctrl-t:last'  \
    --bind 'ctrl-b:first' \
    --bind 'enter:reload(main {+})+clear-query' \
    --bind 'ctrl-f:execute(favorite {})'

exit 0
