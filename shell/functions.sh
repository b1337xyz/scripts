# shellcheck disable=SC2046
# shellcheck disable=SC2086
f() { find . -xdev -iname "*${*}*"; }
d() { du -had1 "${1:-.}" 2>/dev/null | sort -h; }
fox() { command firefox "$@" &>/dev/null & disown ; }
za() { command zathura "$@" &>/dev/null & disown ; }
line() { sed "${1}!d" "$2"; }
wall() { awk -F'"' '{print $2}' ~/.cache/xwallpaper 2>/dev/null; }
lyrics() { while :;do clyrics -p -k -s 20 ; sleep 5 ;done; }
calc() { echo "scale=3;$*" | bc -l; }
start_xephyr() { Xephyr -br -ac -noreset -screen 800x600 :1; }
webdav_server() {
    local ip
    ip=$(command ip -br a | awk '/UP/{print substr($3, 1, length($3)-3); exit}')
    rclone serve webdav -L --read-only --addr "$ip:6969" --user "$USER" --pass 123 "${1:-$HOME}"
}
frep() {
    find . -type f -printf '%f\n' | sort | uniq -d |
    sed -e 's/[]\[?\*\$]/\\&/g' | tr \\n \\0 | xargs -0rI{} find . -type f -name '{}'
}
bkp() {
    local output
    if [ -n "$1" ] && ! [ -s "$1" ];then
        output="$1"
        [ "${1##*.}" == "zip" ] && output="${1%.*}_$(date +%Y%m%d).zip"
        shift
    else
        output="bkp_$(date +%Y%m%d).tar.gz"
    fi

    [ -s "$output" ] && { printf '"%s" already exist.\n' "$output"; return 1; }
    case "${output##*.}" in
        zip) zip -r9y "$output" "$@" ;;
        *) tar --numeric-owner -pcaf "$output" "$@" ;;
    esac
}
bkp2() {
    local rpath
    rpath=$(realpath "$1")
    tar --numeric-owner --lzma -pcf "${1}.tar.lzma" \
        --exclude='*__*__*' --exclude='*.git*' --exclude='*venv*' \
        --exclude='*.zip' --exclude='*.7z' --exclude='*.rar' \
        "$rpath" || { rm -v "${1}.tar.lzma" ; return 1; }
}
alljpg() {
    # find "${@:-.}" -maxdepth 1 -type f -iname '*.png' \
    #     -exec sh -c 'convert "$1" "${1%.*}.jpg" && rm -v "$1"' _ '{}' \;
    #     # \( -exec convert '{}' '{}.jpg' \; -a -exec rm -v '{}' \; \)
    find "${@:-.}" -maxdepth 1 -type f \! -name '*.jpg' | while read -r i;do
        mime=$(file -Lbi "$i")
        case "$mime" in
            image/gif*) continue ;;
            image/jpeg*)
                [ "${i##*.}" != "jpg" ] && mv -vn "$i" "${i%.*}.jpg" ;;
            image/*)
                convert -verbose "$i" "${i%.*}.jpg" && rm -v "$i" ;;
        esac
    done
}
ex() {
    [ -f "$1" ] || return 1
    case "$1" in
        *.tar.zst) tar --zstd -xf "$1" ;;
        *.tar.bz2) tar xvjf "$1"   ;;
        *.tar.gz)  tar xvzf "$1"   ;;
        *.tar)     tar xvf "$1"    ;;
        *.bz2)     bunzip2 "$1"    ;;
        *.zst)     unzstd "$1"     ;;
        *.rar)     unrar x -op"${1%.*}" "$1" ;;
        *.zip)     unzip "$1" -d "${1%.*}"   ;;
        *.gz)      gunzip "$1"     ;;
        *.7z)      7z x "$1"       ;;
        *.Z)       uncompress "$1" ;;
    esac
}
repeat() {
    # Repeat n times command
    local max=$1; shift;
    for ((i=1; i <= max ; i++)); do
        eval "$*";
    done
}
loop() {
    local s
    [[ "$1" =~ ^[0-9]+$ ]] && { s=$1; shift; }
    [ -z "$1" ] && { printf 'Usage: loop <seconds> <cmd...>\n'; return 1; }
    while :;do eval "$*"; sleep "${s:-15}"; done
}
lst() {
    local total
    {
        while read -r i;do
            c=$(command ls -1A "$i" | wc -l)
            (( total += c ))
            printf '%4s: %s\n' "$c" "$i"
        done < <(find "${@:-.}" -mindepth 0 -maxdepth 1 -type d);
        printf '%4s: total\n' "$total";
    } | sort -n 
}
lst2() { lst "${@:-.}" | pr -t4w 80; }
lstar() {
    local tmpfile
    for i in "$@";do
        [ -f "$i" ] || continue
        printf '>>> \033[1;31m%s\033[m\n' "$i"
        tar tvf "$i" 2>/dev/null | bat -l ls
        read -rp "extract '$i'? (y/N) " ask
        [ "${ask,,}" == 'y' ] && tar axvf "$i"
    done
    return 0
}
ren5sum() {
    local out path
    for i in "$@";do
        if [ -f "$i" ];then
            path=$(realpath "$i") path=${path%/*}
            out=${path}/$(md5sum "$i" | awk '{print $1}').${i##*.}
            [ -f "$out" ] && continue
            mv -v "$i" "$out"
        fi
    done
}
sort_by_year() {
    for i in *;do printf '%s\n' "$i" ;done | grep -P '(\d{4})' | sort -t '(' -k 2nr # bad but faster

    # find "${@:-.}" -maxdepth 1 -regextype ed -iregex '.*([0-9]\{4\}.*' | while read -r i
    # do
    #     year=$(printf '%s' "$i" | grep -oP '(?<=\()[0-9]{4}(?=\))' | tail -1)
    #     [ -n "$year" ] && printf '%s;%s\n' "$year" "$i"
    # done | sort -n | cut -d';' -f2-
}
bulkrename() {
    local tmpfile
    declare -f -a files=()
    tmpfile=$(mktemp)

    while IFS= read -r -d $'\0' i;do
        files+=("${i#*/}")
        printf '%s\n' "${i#*/}" >> "$tmpfile" 
    done < <(find . -mindepth 1 -maxdepth 1 \! -path '*/\.*' -print0 | sort -z)

    [ "${#files[@]}" -eq 0 ] && return 1
    vim "$tmpfile"

    lines=$(wc -l < "$tmpfile")
    if [ "${#files[@]}" -ne "$lines" ];then
        echo "The number of lines does not match the amount of files!"
    else
        i=0
        # shellcheck disable=SC2094
        while read -r l;do
            if ! [ -s "$l" ] && [ "${files[i]}" != "$l" ];then
                mv -vn -- "${files[i]}" "$l" || break
            fi
            i=$((i+1))
        done < "$tmpfile"
    fi
    command rm "$tmpfile"
}
crc32check() {
    # How it works:
    #   anime_[12345678].ext > 12345678 == crc32

    [ $# -eq 0 ] && { printf 'Usage: anime_check_crc FILE\n'; return 1; }
    command -v cksfv >/dev/null || { printf 'install cksfv\n'; return 1; }
    # command -v crc32 >/dev/null || { printf '"crc32" command not found\n'; return 1; }

    for i in "$@";do
        [ -f "$i" ] || { printf 'File "%s" not found\n' "$i"; continue; }
        # [12345678] or (12345678)
        fname_crc=$(echo "$i" | grep -oP '(?<=(\[|\())[[:alnum:]]{8}(?=(\)|\]))' | tail -1)
        [ -z "$fname_crc" ] && {
            printf 'crc32 pattern not found in "%s"\n' "$i" 1>&2;
            continue;
        }

        src_crc=$(cksfv -v "$i" | sed '/^;/d; s/.*\(.\{8\}\)$/\1/')

        if [ "$fname_crc" = "$src_crc" ];then
            printf '%s \t\e[1;32m%s\e[m\n' "$i" "$src_crc"
        else
            printf '%s \t\e[1;31m%s\e[m\n' "$i" "$src_crc"
        fi
    done
}
crc32rename() {
    [ $# -eq 0 ] && { printf 'Usage: crcrename FILE\n'; return 1; }
    command -v cksfv >/dev/null || { printf 'install cksfv\n'; return 1; }

    for i in "$@";do
        [ -f "$i" ] || { printf 'Not a file: %s\n' "$i"; continue; }
        file -Lbi -- "$i" | grep -q '^video/' || { printf 'Not a video: %s\n' "$i"; continue; }
        crc=$(cksfv -b "$i" | sed '/^;/d; s/.*\(.\{8\}\)$/\1/')
        mv -vn "$i" "${i%.*} [${crc}].${i##*.}" || return 1
    done
}
chgrubbg() {
    if [ -f "$1" ];then
        image="$1"
    elif [ -d "$1" ];then
        image=$(sxiv -qrto "$1" | head -n1)
    else
        image=$(sxiv -qrto ~/Pictures/wallpapers | head -1)
    fi
    case "${image##*.}" in
        jpg|jpeg) sudo convert -verbose "$image" /usr/share/desktop-base/active-theme/grub/grub-16x9.png ;;
        png) sudo cp -v "$image" /usr/share/desktop-base/active-theme/grub/grub-16x9.png ;;
        *) return 1 ;;
    esac
}
dn() {
    find . -mindepth 1 -maxdepth 1 -exec du -sh {} + |
        sort -h | head -n "${1:-10}" | awk -F\\t '{print $2}' |
        tr \\n \\0 | du --files0-from=- -csh | sort -h
}
cpdir() {
    # copy directory structure
    local len dst
    declare -f -a args
    args=("$@")
    len=$(( $# - 1 ))
    dst=${args[len]}
    [ -d "$dst" ] || return 1
    [ "${dst: -1}" = "/" ] && dst=${dst::-1}

    for (( i=0 ; i < "$len" ; i++));do
        src=${args[i]}
        [ "${src: -1}" = "/" ] && src=${src::-1}
        mkdir -v "${dst}/${src}"
    done
}
fixext() {
    local mimetype ext
    for i in "$@";do
        mimetype=$(file -Lbi -- "$i")
        case "${mimetype%;*}" in
            video/x-msvideo)  ext=avi ;;
            video/x-matroska) ext=mkv ;;
            image/jpeg)       ext=jpg ;;
            image/png)        ext=png ;;
            video/mp4)        ext=mp4 ;;
        esac
        [ -n "$ext" ] && [ "${i##*.}" != "$ext" ] && mv -vn -- "$i" "${ext}"
        unset ext
    done
    return 0
}
odr() {
    case "$1" in
        video)
            wget -w 3 -r -nc -A mkv,mp4,avi,mov,qt,wmv,divx,flv,vob \
                --no-parent -l 200 -e robots=off -R "index.html*" -x "$2" 
        ;;
        image)
            wget -w 3 -r -nc -A jpg,jpeg,gif,png,tiff,bmp,svg \
                --no-parent -l 200 -e robots=off -R "index.html*" -x "$2" 
        ;;
        audio)
            wget -w 3 -r -nc -A mp3,opus,flac,wav \
                --no-parent -l 200 -e robots=off -R "index.html*" -x "$2" 
        ;;
        http*)
            wget -w 3 -r -nc --no-parent \
                -l 200 -e robots=off -R "index.html*" -x "$1" 
        ;;
    esac
}
fscripts() {
    find ~/.scripts -type f -size -100k \! -path '*__*__*' \
        \! -iregex '.*\(jpg\|png\)' -print0
}
loc() {
    fscripts | wc -l --files0-from=- | sort -n 
}
toc() {
    fscripts | wc -m --files0-from=- | sort -n
}
soc() {
    fscripts | du -csh --files0-from=- | sort -h
}
aloc() {
    # "actual" lines of code a.k.a without empty lines
    fscripts | xargs -r0 -I{} awk '{ if ( NF > 0 ) l+=1 } END { printf("%4s %s\n", l, FILENAME) }' {} |
        sort -n | awk '{ print $0; total+=$1+0 } END { printf("total: %s\n", total) }'
}
dul() {
    local size files
    for i in */;do
        [ -d "$i" ] || continue
        size=$(du -sh "$i"  | awk '{print $1}')
        files=$(find "$i" -mindepth 1 -maxdepth 1 | wc -l)
        printf '%-5s | %3s | %s\n' "$size" "$files" "$i"
    done | sort -h
}
edalt() {
    awk -v home="$HOME" '/\/themes\//{sub("~", home, $2); printf("%s\0", $2)}' \
        ~/.config/alacritty/alacritty.yml | xargs -0roI{} vim '{}'
}
save_page() {
    wget -e robots=off --random-wait -E -H -k -K -p -U mozilla "$@" 
}
mgrep() {
    [ -z "$1" ] && return 1
    curl -s "$1" | sed 's/<.\?br>//g; s/\&amp;/\&/g' |
        grep -oP 'magnet:\?xt=urn:[a-z0-9]+:[a-z0-9]+(?=&dn=)'
}
trackers_best() {
    local url output
    url=https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt
    output=~/.cache/trackers_best.txt
    curl -s "$url" | grep --color=never '[a-z]' | tee "$output"
    xclip -sel clip -i "$output" 
}
fvideo() {
    find . -iregex '.*\.\(mkv\|webm\|flv\|ogv\|ogg\|avi\|ts\|mts\|m2ts\|mov\|wmv\|rmvb\|mp4\|m4v\|m4p\|mpg\|mpeg\|3gp\|gif\)$'
}
fimage() {
    find . -iregex '.*\.\(jpg\|png\|jpeg\|bmp\|tiff\|svg\|gif\|webp\)$'
}
grep_video() {
    grep --color=never -i '\.\(mkv\|webm\|flv\|ogv\|ogg\|avi\|ts\|mts\|m2ts\|mov\|wmv\|rmvb\|mp4\|m4v\|m4p\|mpg\|mpeg\|3gp\|anitsu\)$' "$1"
}
grep_archive() {
    grep --color=never -i '\.\(zip\|rar\|7z\|lzma\|gz\|xz\|tar\|bz2\|arj\)$' "$1"
}
random_img() {
    find ~/Pictures/random -iname '*.jpg' -print0 | shuf -zn1 | xargs -0roI{} drawimg.sh '{}'
}
mvbyext() {
    find "${1:-.}" -maxdepth 1 -type f | while read -r i;do
        ext="${i##*.}"
        [ -z "$ext" ] || [ "${#ext}" -gt 4 ] && continue
        [ -d "$ext" ] || mkdir -v "$ext"
        mv -vn -- "$i" "$ext"
    done
}
mkj() {
    for i in "$@";do
        mkvmerge -J "$i" | jq -r '
.tracks[] |
"\(.type): \(.id) - \(.codec) - \(.properties.language) - \(.properties.track_name) \(
if .properties.default_track then "(default)" else "" end)"'
    done
}
random_str() {
    chr=${1:-a-zA-Z0-9@!<&%\$#_\\-\\.}
    tr -dc "$chr" < /dev/urandom | fold -w "${2:-10}" | head -1
}
iommu_groups() {
    for d in /sys/kernel/iommu_groups/*/devices/*
    do
        n=${d#*/iommu_groups/*}
        n=${n%%/*}
        printf 'IOMMU Group %s ' "$n"
        lspci -nns "${d##*/}"
    done
}
toggle_btf_jit() {
    local target value
    target=/proc/sys/net/core/bpf_jit_enable
    value=$(cat "$target")
    if [ "$value" -eq 1 ];then
        echo 0 | sudo tee "$target"
    else
        echo 1 | sudo tee "$target"
    fi
}
keys() { xev | awk -F'[ )]+' '/^KeyPress/ { a[NR+2] } NR in a { printf "%-3s %s\n", $5, $8 }'; }
uniq_lines() { awk '!seen[$0]++' "$1"; }
psrmem() {
    ps axch -o cmd,rss --sort=-%mem | head -10 |
        awk 'BEGIN { printf("\033[42;30m%-30s %-6s\033[m\n", "CMD", "MEM") } {printf("%-30s %.1f\n", $1, $2/1024)}'
}
freq() {
    while :;do
        awk -F':' '/cpu MHz/{printf("%.0f MHz ", $2)} END {printf "\n"}' /proc/cpuinfo;
        sleep "${1:-3}"
    done
}
pacman_unessential() {
    grep -vFf <(pacman -Sl core | awk '/\[installed\]/{print $2}') <(pacman -Qq) |
        awk '{print} END {printf("total: %s unessential packages installed\n", NR)}' 
}
ffstr() {
    verbose=0
    for i in "$@";do
        case "$i" in
            -v|--verbose) verbose=1 ;;
        esac
    done
    for i in "$@";do
        [ -f "$i" ] || continue
        [ "$verbose" -eq 1 ] && printf 'File: \e[1;35m%s\e[m\n' "$i"
        ffmpeg -i "$i" 2>&1 | awk '
        BEGIN { c=0 }
        {
            if ($0 ~ /Attach/) {
                c++
            } else if ( $0 ~ /Stream/) {
                printf("%s\n", substr($0, 3))
            }
        }
        END { printf("Attachments: %s\n", c) }'
    done
}
show_reserved() {
    [ -b "$1" ] || return 1
    sudo tune2fs -l "$1" | awk -F':' '
    {
        if ( $0 ~ /^Block count/)
            block_count = $2 + 0

        if ( $0 ~ /^Reserved block count/) {
            reserved = $2 + 0
            if ( reserved == 0 ) {
                print $0
                exit
            }
        }

    } END {
        if (reserved)
            printf("%.1f%%\n", reserved * 100 / block_count)
    }'
}
lifetime() {
    sudo smartctl -a "${1:-/dev/sda}" | awk '{
        if ($0 ~ /Device Model/) {
            split($0, a, ":")
            dev = a[length(a)]
            sub(/^[ \t]+/, "", dev)
        }

        if ($0 ~ /Power_On_Hours/) {
            h = $10 + 0
            d = h / 24
            h = h % 24
        }
    } END {
        printf("%s: %.0f days, %.0f hours\n", dev, d, h)
    }' 
}
quote() {
    python3 -c '
from sys import stdin, stdout
from urllib.parse import quote
for i in stdin:
    stdout.write(quote(i.strip()) + "\n")'
}
unquote() {
    python3 -c '
from sys import stdout, stdin
from urllib.parse import unquote
for i in stdin:
    stdout.write(unquote(i.strip()) + "\n")'
}
last_modified() {
    stat -c '%Z' "${@:-.}" | xargs -rI{} date --date='@{}' '+%s %b %d %H:%M %Y' |
    awk -v s=$(date '+%s') '{
S = s - $1
M = int(S / 60)
H = int(M / 60)
d = int(H / 24)
if ( d > 365 ) {
    printf("%d %s %d %s\n", $5, $2, $3, $4)
} else if ( d >= 30 ) {
    printf("%s %d %s\n", $2, $3, $4)
} else if ( d == 1 ) {
    printf("yesterday\n")
} else if ( d > 1 ){
    printf("%d days ago\n", d)
} else if ( H == 1 ) {
    printf("%d hour ago\n", H)
} else if ( H > 1 ) {
    printf("%d hours ago\n", H)
} else if ( M == 1 ) {
    printf("%d minute ago\n", M)
} else if ( M > 1 ) {
    printf("%d minutes ago\n", M)
} else if ( S == 1 ) {
    printf("%d second ago\n", S)
} else if ( S > 1 ) {
    printf("%d seconds ago\n", S)
} else if ( S == 0 ) {
    printf("now\n");
} else {
    printf("%s %d %s\n", $2, $3, $4)
}}'
}
gcd() {
    local width=$1
    local height=$2
    _gcd() {
        test $2 -eq 0 && { echo -n "$1"; return; }
        _gcd $2 $(($1 % $2))
    }
    r=$(_gcd "$width" "$height")
    rw=$(( width  / r ))
    rh=$(( height / r ))
    echo "${rw}:$rh"
}
todo() {
    TODOFILE=${TODOFILE:-${HOME}/.todo}
    [ -s "$TODOFILE" ] && sed -i '/^[ \t]*\?$/d' "$TODOFILE"
    case "$1" in
        ed) [ -s "$TODOFILE" ] && "${EDITOR:-vim}" "$TODOFILE" ;;
        ls)
            if test -s "$TODOFILE";then
                printf '\n\e[1;30;43m TODO \033[m\n'
                cat "$TODOFILE"; echo
            fi
        ;;
        add)
            shift
            [ -n "$1" ] && printf '[%s] %s\n' \
                "$(date +%Y.%m.%d' '%H:%M)" "$*" | tee -a "$TODOFILE"
        ;;
        *) echo 'Usage: todo [ed ls add] <TODO>' ;;
    esac
}
ftext() {
    find . -type f -exec file -i {} + | grep -oP '.*(?=:[\t ]*text/)'
}
paclog() {
    # last pkgs of <status>
    grep "${1:-upgraded}" /var/log/pacman.log | tac | awk -F'T' '{
        if ( substr($1, length($1)-1) != x && x)
            exit
        print $0
        x = substr($1, length($1)-1)
    }' | tac
}
random_anime_quote() {
    # Default rate limit is 100 requests per hour.
    local url="https://animechan.vercel.app/api/random"
    curl -s "$url" | jq -Mrc '"\(.anime)\n\"\(.quote)\" - \(.character)"'
}
random_color() {
    clear
    find ~/.scripts/playground/shell/Colors \
        -maxdepth 1 -type f -print0 | shuf -zn 1 | xargs -r0 bash
    printf '\e[0m'
}
upload() { curl -F"file=@$*" https://0x0.st; }
check_leek() {
    grep --exclude-dir=".git" --color -rniP \
        'api.key|secret|token|password|passwd|(\d{1,3}\.){3}\d+'
}
fib() {
    local a b n
    a=0 b=1 n=${1:-5}
    for (( i = 0; i <= n; i++ ));do
        echo -n "$a "
        fn=$((a + b)) a=$b b=$fn
    done; echo
}
