bcat() { aria2c -S "$1";  }
bthead() {
    aria2c -S "$1" | sed '/^idx\|path\/length/q'
}
dubt3() {
    [ $# -eq 0 ] && { dubt3 ./*.torrent; return; }
    aria2c -S "$@" | awk '{
    if ($0 ~ /^Total/) size = $3
    if ($0 ~ / 1\|\.\//) {
        split($0, a, "/")
        printf("%-8s\t%s\n", size, a[2])
    }
}'
}
dubt2() {
    aria2c -S "$1" | awk '/^Total|\|/{
    if ($0 ~ /^Total/) total = $3

    if ($0 ~ /[0-9]\|\.\//) {
        split($0, a, "/")
        fname = a[length(a)]
        idx = substr(a[1], 1, length(a[1]) - 2)
    } else if ($0 ~ / \|[0-9]*\.?[0-9]*?[KMG]iB/) {
        size = substr($1, 2)
        printf("%8s \033[1;31m%4s\033[m: %s\n", size, idx, fname)
    }
} END {
    printf("%s total\n", total)
}'

}
rentorrent() {
    local torrent
    find "${@:-.}" -maxdepth 1 -type f -iname '*.torrent' | while read -r torrent;do
        torrent_name=$(aria2c -S "$torrent" |
            awk -F'/' '/ 1\|\.\//{print $2".torrent" ; exit}')
        torrent_path=${torrent%/*}/${torrent_name}
        [ "$torrent_path" != "$torrent" ] &&
            mv -vn "$torrent" "$torrent_path"
    done
    return 0
}
m2t() {
    local tmpdir torrent torrent_name
    tmpdir=$(mktemp -d)
    aria2c --bt-save-metadata --bt-metadata-only --bt-stop-timeout=90 \
        -d "$tmpdir" "$1" || { rm -rf "$tmpdir"; return 1; }
    torrent=$(find "$tmpdir" -type f)
    torrent_name=$(aria2c -S "$torrent" | awk -F'/' '/ 1\|\.\//{print $2".torrent"}')
    mv -v "$torrent" "$torrent_name"
    rm -rf "$tmpdir"
}
btdiff() {
    # shellcheck disable=SC2046
    if [ $(file -Lbi -- "$1" "$2" | grep -c 'x-bittorrent') -eq 2 ];then
        diff --color <(aria2c -S "$1") <(aria2c -S "$2")
    fi
}
btch() {
    local torrent

    torrent="$1"
    [ -z "$1" ] && torrent=$(ls -1 ./*.torrent | head -1)

    file -Lbi -- "$1" | grep -q bittorrent || return 1
    aria2c -S "$torrent" | awk -F'|' '/[0-9]\|\.\//{print $2}' | sort | while read -r i;do
        if [ -f "$i" ];then
            printf '[\e[1;32mOK\e[m] %s\n' "$i"
        else
            printf '[\e[1;30mOK\e[m] %s not found\n' "$i"
            #read -sp 'Press ENTER to continue' ;  printf '%20s\r' ' '
        fi
    done
}
lsbt() {
    if [ -z "$1" ];then
        aria2c -S ./*.torrent | awk '/[0-9]\|\.\//' | sort -n || return 1
    else
        for i in "$@";do
            aria2c -S "$i" | awk '/[0-9]\|\.\//' | sort -n || return 1
        done
    fi
}
btlst() {
    aria2c -S ./*.torrent | awk -F'/' '
BEGIN { total = 0 }
/[0-9]\|\.\//{
    split($1, a, "|")
    c = a[1] + 0
    curr_torrent = $2
    if ( !( torrent_name ) ) {
        torrent_name = curr_torrent
    } else if ( curr_torrent != torrent_name ) {
        printf("%s %s\n", cc, torrent_name)
        torrent_name = curr_torrent
        total += cc
    }
    cc = c
} END {
    total += cc
    printf("%s total\n", total)
}' | sort -n
}
btsel() {
    aria2c -S "$1" | awk -F'|' '/[0-9]\|\.\//{
        sub(/^[ \t]*/, "", $0);
        split($2, a, "/");
        printf("%s|%s\n", $1, a[length(a)])
    }' | fzf -m | grep -oP '^\d*(?=\|)' | tr \\n ',' | sed 's/,$//' |
        xargs -rI{} aria2c --bt-remove-unselected-file --select-file "{}" "$1" 
}
