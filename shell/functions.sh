# shellcheck disable=SC2012 
# shellcheck disable=SC2094
fin() { find . -iname "*${*}*"; }
fre() { find . -iregex ".*${*}.*"; }
d() { du -had1 "${1:-.}" 2>/dev/null | sort -h; }
fox() { command firefox "$@" &>/dev/null & disown ; }
za() { command zathura "$@" &>/dev/null & disown ; }
fr() { find . -type f -iregex "$@"; }
line() { sed "${1}!d" "$2"; }
wallpaper() { awk -F'"' '{print $2}' ~/.cache/xwallpaper 2>/dev/null; }
lyrics() { while :;do clyrics -p -k -s 20 ; sleep 5 ;done; }
start_xephyr() {
    Xephyr -br -ac -noreset -screen 800x600 :1
}
webdav_server() {
    local ip
    ip=$(command ip -br a | awk '/UP/{print substr($3, 1, length($3)-3)}')
    rclone serve webdav -L --read-only --addr "$ip:56909" --user anon --pass 123 "${1:-$HOME}"
}
frep() {
    find . -type f -printf '%f\n' | sort | uniq -d | while read -r i;do
        find . -name "$i" -type f
    done
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
png2jpg() {
    find "${@:-.}" -maxdepth 1 -type f -iname '*.png' \
        \( -exec convert '{}' '{}.png' \; -a -exec rm -v '{}' \; \)
}
ex() {
    for i in "$@";do
        case "$i" in
            *.tar.bz2) tar xvjf "$i" ;;
            *.tbz2) tar xvjf "$i" ;;
            *.tar.gz) tar xvzf "$i" ;;
            *.tar) tar xvf "$i" ;;
            *.bz2) bunzip2 "$i" ;;
            *.tgz) tar xvzf "$i" ;;
            *.rar) unrar x "$i" ;;
            *.zip) unzip "$i" ;;
            *.gz) gunzip "$i" ;;
            *.7z) 7z x "$i" ;;
            *.Z) uncompress "$i" ;;
            -*) continue ;;
            *) printf '"%s" cannot be extracted\n' "$i" ;;
        esac || { printf '\nfailed to extract "%s" :(\n' "$i"; break; }
    done
    return 0
}
repeat() {
    # Repeat n times command
    local max=$1; shift;
    for ((i=1; i <= max ; i++)); do
        eval "$*";
    done
}
loop() {
    local s=$1; shift;
    [[ $s =~ ^[0-9]*$ ]] || { printf 'Usage: loop <sleep> <command...>\n'; return 1; }
    while :;do
        eval "$*";
        sleep "$s";
    done
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
    tmpfile=$(mktemp)
    for i in "$@";do
        [ -f "$i" ] || continue
        printf '>>> \033[1;31m%s\033[m\n' "$i"
        tar tvf "$i" 2>/dev/null | tee "$tmpfile" | less
        [ -s "$tmpfile" ] || continue
        read -rp "extract '$i'? (y/N) " ask
        [ "${ask,,}" == 'y' ] && { tar xvf "$i"; break; }
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
    ls -1 "${1:-.}" | sort -t '(' -k 2nr
    return
    if [ $# -eq 0 ];then
        find . -maxdepth 1 -regextype ed -iregex '.*([0-9]\{4\}.*' | while read -r i;do
            year=$(printf '%s' "$i" | grep -oP '(?<=\()[0-9]{4}(?=\))' | tail -1)
            [ -z "$year" ] && continue
            printf '%s;%s\n' "$year" "$i"
        done
    else
        for i in "$@";do
            year=$(printf '%s' "$i" | grep -oP '(?<=\()[0-9]{4}(?=\))' | tail -1)
            [ -z "$year" ] && continue
            printf '%s;%s\n' "$year" "$i"
        done
    fi | sort -n | while read -r l;do
        printf '%s\n' "${l##*;}"
    done
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

    lines=$(wc -l "$tmpfile" | cut -d' ' -f1)
    if [ "${#files[@]}" -ne "$lines" ];then
        echo "The number of lines does not match the amount of files"
        rm "$tmpfile"
        return 1
    fi

    i=0
    # shellcheck disable=SC2094
    while read -r l;do
        if ! [ -s "$l" ] && [ "${files[i]}" != "$l" ];then
            mv -vn -- "${files[i]}" "$l" || { rm "$tmpfile"; return 1; }
        fi
        i=$((i+1))
    done < "$tmpfile"
    command rm -f "$tmpfile"
}
crc32check() {
    # How it works:
    #   anime_[12345678].ext > 12345678 == file crc32

    [ $# -eq 0 ] && { printf 'Usage: anime_check_crc FILE\n'; return 1; }
    command -v cksfv >/dev/null || { printf 'install cksfv\n'; return 1; }
    # command -v crc32 >/dev/null || { printf '"crc32" command not found\n'; return 1; }

    for i in "$@";do
        [ -f "$i" ] || { printf 'File "%s" not found\n' "$i"; continue; }
        fname_crc=$(echo "$i" | grep -oP '(?<=(\[|\())[[:alnum:]]{8}(?=(\)|\]))' | tail -n1) # [12345678] or (12345678)
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
        file -Lbi -- "$i" | grep -q video || { printf 'Not a video: %s\n' "$i"; continue; }
        ext="${i##*.}"
        crc=$(cksfv -b "$i" | sed '/^;/d; s/.*\(.\{8\}\)$/\1/')
        mv -vn "$i" "${i%.*} [${crc}].$ext" || return 1
    done
}
copy_to_sel() {
    local tmpfile
    tmpfile=$(mktemp)
    vim "$tmpfile"
    [ -s "$tmpfile" ] && xclip -sel clip "$tmpfile"
    rm -f "$tmpfile" &>/dev/null
}
chgrubbg() {
    if [ -f "$1" ];then
        image="$1"
    elif [ -d "$1" ];then
        image=$(sxiv -qrto "$1" | head -n1)
    else
        image=$(sxiv -qrto ~/Pictures/wallpapers | head -n1)
    fi
    case "${image##*.}" in
        jpg|jpeg) sudo convert -verbose "$image" /usr/share/desktop-base/active-theme/grub/grub-16x9.png ;;
        png) sudo cp -v "$image" /usr/share/desktop-base/active-theme/grub/grub-16x9.png ;;
        *) return 1 ;;
    esac
}
dn() {
    [ -z "$1" ] && return 1
    find . -mindepth 1 -maxdepth 1 -exec du -sh {} \; |
        sort -h | head -n "$1" | awk -F\\t '{print $2}' |
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
        ext=
        mimetype=$(file -Lbi -- "$i")
        case "${mimetype%;*}" in
            video/x-msvideo) ext=avi ;;
            video/x-matroska) ext=mkv ;;
            image/jpeg) ext=jpg ;;
            image/png) ext=png ;;
            video/mp4) ext=mp4 ;;
        esac
        if [ -n "$ext" ];then
            if [ "${i##*.}" != "$ext" ];then
                if [ "${i##*.}" = "anitsu" ];then
                    mv -v "$i" "${i%.*}.${ext}"
                else
                    mv -v "$i" "${i}.${ext}"
                fi || break
            fi
        fi
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
    local target
    target=~/.scripts
    find "${@:-$target}" \( -iregex '.*\.\(sh\|py\)' -or -regex '.*_functions' \) \
        ! -path '*__*__*' ! -path '*/venv*' -print0
}
loc() {
    fscripts "$@" | wc -l --files0-from=- | sort -n 
}
toc() {
    fscripts "$@" | wc -m --files0-from=- | sort -n
}
soc() {
    fscripts "$@" | du -csh --files0-from=- | sort -h
}
aloc() {
    # "actual" lines of code, without empty lines
    fscripts "$@" | xargs -r0 -I{} awk '{ if ( NF > 0 ) l+=1 } END { printf("%4s %s\n", l, FILENAME) }' {} |
        sort -n | awk '{ print $0; total+=$1+0 } END { printf("total: %s\n", total) }'
}
dul() {
    local size files
    for i in */;do
        [ -d "$i" ] || continue
        size=$(du -sh "$i"  | awk '{print $1}')
        files=$(ls -1 "$i" | wc -l)
        printf '%-5s | %3s | %s\n' "$size" "$files" "$i"
    done | sort -h
}
edalt() {
    theme=$(awk '/themes\//{gsub("~", "'"$HOME"'", $2) ; print $2 }' \
        ~/.config/alacritty/alacritty.yml)
    [ -f "$theme" ] && vim "$theme"
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
    find "${1:-.}" -iregex '.*\.\(mkv\|webm\|flv\|ogv\|ogg\|avi\|ts\|mts\|m2ts\|mov\|wmv\|rmvb\|mp4\|m4v\|m4p\|mpg\|mpeg\|3gp\|gif\)$'
}
fimage() {
    find "${1:-.}" -iregex '.*\.\(jpg\|png\|jpeg\|bmp\|tiff\|svg\|gif\)$'
}
grep_video() {
    grep --color=never -i '\.\(mkv\|webm\|flv\|ogv\|ogg\|avi\|ts\|mts\|m2ts\|mov\|wmv\|rmvb\|mp4\|m4v\|m4p\|mpg\|mpeg\|3gp\|anitsu\)$' "$1"
}
grep_archive() {
    grep --color=never -i '\.\(zip\|rar\|7z\|lzma\|gz\|xz\|tar\|bz2\|arj\)$' "$1"
}
_help() {
    local d
    d=~/Documents/cheat
    case "$1" in
        mkvmerge) cat "${d}/mkvmerge" ;;
        *) ls "$d" ;;
    esac
}
shwatch() {
    local tmpfile
    tmpfile=$(mktemp /tmp/tmp.XXXXXXXX.sh)
    echo "#/bin/sh" >> "$tmpfile"
    vim "$tmpfile"
    chmod +x "$tmpfile"
    watch -n 5 -t "$tmpfile"
    rm "$tmpfile"
}
random_img() {
    img=$(find ~/Pictures/random -iname '*.jpg' | shuf -n1)
    drawimg.sh "$img"
}
mvbyext() {
    find "${1:-.}" -maxdepth 1 -type f | while read -r i;do
        ext="${i##*.}"
        [ -z "$ext" ] || [ "${#ext}" -gt 4 ] && continue
        [ -d "$ext" ] || mkdir -v "$ext"
        mv -vn "$i" "$ext"
    done
}
mkj() {
    for i in "$@";do
        mkvmerge -J "$i" | jq -r '
.tracks[] |
"\(.type): \(.id) - \(.codec) - \(.properties.language) - \(.properties.track_name) \(
if .properties.default_track then "(default)" else "" end)"
'
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
getkeys() { xev | awk -F'[ )]+' '/^KeyPress/ { a[NR+2] } NR in a { printf "%-3s %s\n", $5, $8 }'; }
uniq_lines() {
    if [ -f "$1" ];then
        awk '!seen[$0]++' "$1"
    else
        awk '!seen[$0]++'
    fi
}
psrmem() {
    ps axch -o cmd,rss --sort=-%mem | head -10 |
        awk 'BEGIN { printf("\033[42;30m%-30s %-6s\033[m\n", "CMD", "MEM") } {printf("%-30s %.1f\n", $1, $2/1024)}'
}
freq() {
    while :;do
        awk -F':' '/cpu MHz/{printf("%.0f MHz ", $2)} END {printf "\n"}' /proc/cpuinfo;
        sleep "${1:-2}" || break
    done
}
pacman_unessential() {
    grep -vFf <(pacman -Sl core | awk '/\[installed\]/{print $2}') <(pacman -Qq) |
        awk '{ if ($0 ~ /^lib/) next ; c++ ; print $0 }
        END { printf("total: %s unessential packages installed\n", c) }' 
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
                c+=1
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
    sed '
    s/%/%25/g;  s/ /%20/g;  s/\[/%5B/g;
    s/\]/%5D/g; s/</%3C/g;  s/>/%3E/g;
    s/#/%23/g;  s/{/%7B/g;  s/}/%7D/g;
    s/|/%7C/g;  s/\\/%5C/g; s/\^/%5E/g;
    s/~/%7E/g;  s/`/%60/g;  s/\;/%3B/g;
    s/?/%3F/g;  s/@/%40/g;  s/=/%3D/g;
    s/&/%26/g;  s/\$/%24/g; s/(/%28/g;
    s/)/%29/g'
}
unquote() {
    sed '
    s/%25/%/g;  s/%20/ /g;  s/%5B/\[/g;
    s/%5D/\]/g; s/%3C/</g;  s/%3E/>/g;
    s/%23/#/g;  s/%7B/{/g;  s/%7D/}/g;
    s/%7C/|/g;  s/%5C/\\/g; s/%5E/\^/g;
    s/%7E/~/g;  s/%60/`/g;  s/%3B/\;/g;
    s/%3F/?/g;  s/%40/@/g;  s/%3D/=/g;
    s/%26/&/g;  s/%24/\$/g; s/%28/(/g;
    s/%29/)/g'
}
