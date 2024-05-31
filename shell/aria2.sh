bcat() { aria2c -S "$1";  }
bthead() { aria2c -S "$1" | sed '/^idx\|path\/length/q'; }
btbody() { aria2c -S "$1" | sed -n '/^idx\|path\/length/,$p'; }

getHashes() {
    [ -z "$1" ] && set -- ./*.torrent
    aria2c -S "$@" | awk '{
        if ($1 ~ /^>>>/) {
            s = substr($0, 36)
            sub(/.\.\.\.$/, "", s)
            print s
        } else if ($1 ~ /^Info/) {
            print $3
        }
    }'
}

dubt() {
    [ $# -eq 0 ] && set -- ./*.torrent
    aria2c -S "$@" | awk '/^Total | 1\|\.\//{
        if ($0 ~ /^Total/) {
            unit = $3
            psize = substr($3, 1, length($3) - 3) + 0
            if (unit ~ /GiB/) {
                total += psize * 1024
            } else if (unit ~ /KiB/) {
                total += psize / 1024
            } else {
                total += psize
            }
            next
        }
        split($0, a, "/")
        torrent_name = a[2]
        printf("%8s\t%s\n", unit, torrent_name)
    } END {
        if (total >= 1024) {
            total /= 1024
            printf("%.1fGiB total\n", total)
        } else {
            printf("%.1fMiB total\n", total)
        }
    }'
}

dufbt() {
    [ -f "$1" ] || { printf 'Usage: dubt2 <TORRENT FILE>\n'; return 1; }
    aria2c -S "$1" | awk -v n=0 '{
    if ($0 ~ /^Total/) total = $3
    if ($0 ~ /^idx\|path\/length/) n=1
    if (n == 0) next
    if ($0 ~ /^[\s\t ]+[0-9]+\|\.\//) {
        match($0, /^[\s\t ]+([0-9]+)\|(.*)/, s)
        sub(/.*\//, "", s[2])
    } else if (! ($0 ~ /^---/) ) {
        match($1, /\|([^ ]+)/, size)
        printf("%8s \033[1;31m%4s\033[m: %s\n", size[1], s[1], s[2])
    }} END { printf("%s total\n", total) }'
}

pptorrent() {
    [ -f "$1" ] || { printf 'Usage: pptorrent <TORRENT FILE>\n'; return 1; }

    aria2c -S "$1" | awk -v n=0 '{
    if ($0 ~ /^idx\|path\/length/) n=1
    if (n == 0) next
    if ($0 ~ /^[\s\t ]+[0-9]+\|\.\//) {
        match($0, /^[\s\t ]+([0-9]+)\|\.\/(.*)/, s)
    } else if (! ($0 ~ /^---/) ) {
        match($1, /\|([^ ]+)/, size)
        printf("\033[1;35m%s\033[m) %s (%s)\n", s[1], s[2], size[1])
    }}'

}


dubt3() {
    [ $# -eq 0 ] && set -- ./*.torrent
    aria2c -S "$@" | awk '/^Total | 1\|\.\//{
        if ($0 ~ /^Total/) {
            size = $3
            next
        }
        split($0, a, "/")
        printf("%-8s\t%s\n", size, a[2])
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
    aria2c --file-allocation=none --bt-save-metadata --bt-metadata-only --bt-stop-timeout=90 \
        -d "$tmpdir" "$1" || { rm -dv "$tmpdir"; return 1; }

    torrent=$(find "$tmpdir" -type f)
    if [ -f "$torrent" ];then
        torrent_name=$(aria2c -S "$torrent" | awk -F'/' '/ 1\|\.\//{print $2".torrent"}')
        mv -v "$torrent" "${torrent_name:-.}"
        rm -vd "$tmpdir"
    fi
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
    [ -z "$1" ] && torrent=$(printf '%s\n' ./*.torrent | head -1)

    file -Lbi -- "$1" | grep -q bittorrent || return 1
    aria2c -S "$torrent" | awk -F'\\|\\./' '/[0-9]\|\.\//{printf("./%s\n", $2)}' | sort | while read -r i;do
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
    file -Lbi -- "$1" | grep -q bittorrent || return 1
    aria2c -S "$1" | awk -F'\\|\\./' '/[0-9]\|\.\//{
        sub(/^[ \t]*/, "", $0);
        printf("%s|%s\n", $1, $2)
    }' | fzf -m --bind 'ctrl-a:select-all' | grep -oP '^\d+(?=\|)' | tr \\n ',' | sed 's/,$//' |
        xargs -orI{} aria2c --bt-remove-unselected-file --select-file '{}' "$1" 
}

addUri() {
    data=$(printf '{
        "jsonrcp":"2.0", "id":"a",
        "method":"aria2.addUri", "params":[["%s"], {"dir": "%s"}]
    }' "$1" "${2:-${HOME}/Downloads}" | jq -Mc .)
    curl -s "http://localhost:6800/jsonrpc" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -d "$data" -w '\n'
}


# addTorrent() {
#     local torrent data
#     [ -f "$1" ] || return 1
#     torrent=$(base64 -i -w 0 "$1")
#     data=$(printf '{
#         "jsonrpc":"2.0", "id":"a",
#         "method":"aria2.addTorrent",
#         "params":["%s"]
#     }' "$torrent" | jq -Mc .)
#     curl -s 'http://127.0.0.1:6800/jsonrpc' \
#         -H "Content-Type: application/json" \
#         -H "Accept: application/json" \
#         -d "$data" -w '\n'
# }
