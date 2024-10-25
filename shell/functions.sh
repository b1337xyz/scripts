# shellcheck disable=SC2046
# shellcheck disable=SC2086
#
# Reference:
#   https://tldp.org/LDP/abs/html/sample-bashrc.html
#   https://github.com/WANDEX/scripts-wndx
#   https://gitlab.com/TheOuterLinux/Command-Line/-/blob/master/System/Terminals%20and%20Muxinators/bashrc/bashrc%20-%20Basic.txt

VideoPattern='\.\(mkv\|webm\|flv\|ogv\|ogg\|avi\|ts\|mts\|m2ts\|mov\|wmv\|rmvb\|mp4\|m4v\|m4p\|mpg\|mpeg\|3gp\|gif\)$'
ImagePattern='\.\(jpg\|png\|jpeg\|bmp\|tiff\|svg\|webp\)$'
ArchivePattern='\.\(zip\|rar\|7z\|lzma\|gz\|xz\|tar\|bz2\|arj\)$'
UserAgent='Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/114.0'

za() { zathura "$@" >/dev/null 2>&1 & disown; }
f() { find . -xdev -iname "*${*}*"; }
d() { du -had1 "${1:-.}" 2>/dev/null | sort -h; }
wall() { awk -F'"' '{print $2}' ~/.cache/xwallpaper 2>/dev/null; }
lyrics() { while :;do clyrics -p -k -s 20 ; sleep 5 ;done; }
calc() { echo "scale=3;$*" | bc -l; }
start_xephyr() { Xephyr -br -ac -noreset -screen 800x600 :1; }
keys() { xev | awk -F'[ )]+' '/^KeyPress/ { a[NR+2] } NR in a { printf "%-3s %s\n", $5, $8 }'; }
0x0() { curl -F"file=@$*" https://0x0.st | tee -a ~/.cache/0x0.st; }
transfer.sh() { curl --upload-file "$1" https://transfer.sh | tee -a ~/.cache/transfer.sh; }
bashupload() { curl bashupload.com -T "$1"; }
uniq_lines() { awk '!seen[$0]++' "$1"; }
fvideo() { find . -iregex ".*$VideoPattern"; }
fimage() { find . -iregex ".*$ImagePattern"; }
farchive() { find . -iregex ".*$ArchivePattern"; }
grep_video() { grep --color=never -i "$VideoPattern" "$1"; }
grep_image() { grep --color=never -i "$ImagePattern" "$1"; }
grep_archive() { grep --color=never -i "$ArchivePattern" "$1"; }
curlt() { curl -s "$1" | sed 's/<\/*[^>]*>/ /g; s/&nbsp;/ /g'; } # curl html as simple text (from WANDEX scripts-wndx)
lowercase() { tr '[:upper:]' '[:lower:]'; }
uppercase() { tr '[:lower:]' '[:upper:]'; }
first() { awk '{print $1}'; }
latest() { command ls -1trc "${@:-.}" | tail -1; }

gmd() {
    # grep links in markdown files
    grep -ornP '\[[^\]]+\]\(http[^\)]+\)' "${1:-.}" # | grep -oP 'http[^\)]+'
}

# fext() { find . -type f -name '*\.*' | grep -o '[^\.]*$' | sort -u; }
fext() {
    find . -maxdepth "${1:-9}" -type f -name '*\.*' | grep -o '[^\.]*$' |
        awk '{a[$0] += 1} END {for ( i in a ) printf("%s\t%s\n", a[i], i)}' | sort -n
}

histcount() {
    # Output:
    #  ...
    #  185 git
    #  223 pacman
    #  411 vi
    #  441 sudo
    #  999 neofetch
    HISTTIMEFORMAT='' history | sed 's/[\t ]*[0-9]\+[\t ]*\([^ ]*\).*/\1/' | sort | uniq -c | sort -n | tail -10
}

cpl() {
    # Example:
    #   cpl <files> 
    #   cd ~/Downloads
    #   cpl # <files> are copied to the current directory

    local cache=/tmp/.copy_later
    if [ -f "$1" ] || [ -d "$1" ];then
        command rm "$cache" 2>/dev/null
        realpath -- "$@" >> "$cache"
    elif [ -f "$cache" ];then
        while read -r i;do
            [ -e "$i" ] && cp -rvn "$i" .
        done < "$cache"
    else
        printf 'nothing to do\n'
    fi
}

arc() {
    # Archive file
    local filename basename archive
    filename=${1%%+(/)} # remove `file///+` if present at the end of "$1" (requires extglob)
    basename=${filename##*/}
    archive=${basename}.tar
    n=1
    while [ -e "$archive" ];do
        archive=${basename}.${n}.tar
        n=$((n+1))
    done
    printf '> %s\n' "$archive" 
    tar cf "$archive" "$@"
}

line() {
    # Example: `line 1 ~/.bashrc` or `cat ~/.bashrc | line 10`
    if [ -f "$2" ];then sed "${1}!d" "$2"; else sed "${1}!d"; fi
}

webdav_server() {
    local ip
    ip=$(command ip -br a | awk '/UP/{print substr($3, 1, length($3)-3); exit}')
    rclone serve webdav -L --read-only --no-modtime --no-checksum \
        --addr "$ip:6969" --user "$USER" --pass 123 "${1:-$HOME}"
}

frep() {
    # find repeated file
    local type depth
    while [ $# -gt 0 ];do
        case "$1" in
            -t|-type) shift; type=$1 ;;
            -d|-depth) shift; depth=$1 ;;
            -*) shift; printf 'Usage: frep [-type -depth]\n'; return ;;
        esac
        shift
    done
    find . -maxdepth "${depth:-4}" -type "${type:-f}" -printf '%f\n' | sort | uniq -d |
    sed -e 's/[]\[?\*\$]/\\&/g' | tr \\n \\0 | xargs -0rI{} find . -type "${type:-f}" -name '{}'
}

bkp() {
    local bname output
    [ -e "$1" ] || return 1
    bname=$(basename "$1")
    output="${bname}.$(date +%Y.%m.%d).tar.lzma"
    tar --numeric-owner --lzma -pcf "$output" "$1" || { rm -v "$output" ; return 1; }
}

alljpg() {
    # Warning: this will convert to jpeg and DELETE all images that aren't jpeg
    
    # find "${@:-.}" -maxdepth 1 -type f -iname '*.png' \
    #     -exec sh -c 'convert "$1" "${1%.*}.jpg" && rm -v "$1"' _ '{}' \;
    #     # \( -exec convert '{}' '{}.jpg' \; -a -exec rm -v '{}' \; \)
    find "${@:-.}" -maxdepth 1 -type f \! -name '*.jpg' | while read -r i
    do
        mime=$(file -Lbi -- "$i")
        case "${mimetype%;*}" in
            image/gif) continue ;;
            image/jpeg)
                [ "${i##*.}" != "jpg" ] && mv -vn -- "$i" "${i%.*}.jpg" ;;
            image/*)
                convert -verbose "$i" "${i%.*}.jpg" && rm -v -- "$i" ;;
        esac
    done
}

ex() {  # decompress stuff
    local exit_status
    for i in "$@";do
        [ -f "$i" ] && [ -r "$i" ] || continue
        case "$i" in
            *.tar.zst)  tar --zstd -xf "$i" ;;
            *.tar.xz)   tar xvJf "$i"   ;;
            *.tar.bz2)  tar xvjf "$i"   ;;
            *.tar.gz)   tar xvzf "$i"   ;;
            *.tar)      tar xvf "$i"    ;;
            *.bz2)      bunzip2 "$i"    ;;
            *.zst)      unzstd "$i"     ;;
            *.gz)       gunzip "$i"     ;;
            *.rar)      unrar x -op"${i%.*}" "$i" ;;
            #*.zip)     unzip "$i" -d "${i%.*}" ;;
            *.7z|*.zip) 7z x -o"${i%.*}" "$i" ;;
            *.Z)        uncompress "$i" ;;
            *)          continue ;;
        esac
        exit_status=$?
        [ "$exit_status" -ne 0 ] && { printf 'Failed to extract "%s"\n' "$i"; return ${exit_status}; }
        [[ "$1" = -[rd] ]] && command rm -v "$i"
    done
    return 0
}

repeat() { # Repeat n times command
    local max=$1; shift;
    for ((i=1; i <= max ; i++)); do
        eval "$*";
    done
}

loop() { # loop a command every n seconds
    local s
    [[ "$1" =~ ^[0-9\.]+$ ]] && { s=$1; shift; }
    [ -z "$1" ] && { printf 'Usage: loop <sleep> <cmd...>\n'; return 1; }
    while :;do eval "$*"; echo "Exit code: $?"; sleep "${s:-10}" || break; done
}

_loop() {
    local cur
    _get_comp_words_by_ref cur
    # shellcheck disable=SC2207
    COMPREPLY=( $( compgen -W "$(compgen -c)" -- "$cur" ) )
} && complete -F _loop loop
wait_for() {
    [ $# -lt 2 ] && return 1
    local prog
    prog=$1
    shift
    while pgrep -f "$prog" >/dev/null 2>&1;do sleep 1;done && eval "$*"
}

lst() {
    # list the total of files in the current directory and its subdirectories

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

lst2() {
    # same as `lst` but with columns
    lst "${@:-.}" | pr -t4w 80;
}

lstar() {
    # list and extract tar files
    for i in "$@";do
        [ -f "$i" ] || continue
        printf '>>> \033[1;31m%s\033[m\n' "$i"
        tar tvf "$i" 2>/dev/null | less
        read -rp "extract '$i'? (y/N) " ask
        [ "${ask,,}" = 'y' ] && tar axvf "$i"
    done
    return 0
}

ren5sum() {
    # rename file to <md5sum>.<ext>
    local out path
    for i in "$@";do
        if [ -f "$i" ];then
            path=$(realpath "$i") path=${path%/*}
            out=${path}/$(md5sum "$i" | awk '{print $1}').${i##*.}
            [ -f "$out" ] && continue
            mv -nv -- "$i" "$out"
        fi
    done
}

sort_by_year() {
    # Given the following folders in the current directory:
    #   Folder (2013)
    #   Folder (2009)
    #   Folder (2000)
    # List and sort then by (<YEAR>)

    printf '%s\n' ./* | awk '{
        y = gensub(/.*\(([0-9]{4})\).*/, "\\1", "g")
        if (y ~ /^[0-9]{4}$/) {
            sub("(" y ")", "\033[1;34m" y "\033[m")
            printf("%s,%s\n", y, $0)
        }
    }' | sort -n | cut -d',' -f2-
}

crc32check() {
    # How it works:
    #   anime_[12345678].ext > 12345678 = crc32

    [ $# -eq 0 ] && { printf 'Usage: crc32check <FILES>\n'; return 1; }
    command -v cksfv >/dev/null || { printf 'install cksfv\n'; return 1; }
    # command -v crc32 >/dev/null || { printf '"crc32" command not found\n'; return 1; }

    for i in "$@";do
        # [12345678] or (12345678)
        fname_crc=$(printf '%s' "$i" | grep -oP '(?<=(\[|\())[[:alnum:]]{8}(?=(\)|\]))' | tail -1)
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

crc32rename() { # add [<crc32>] to the filename

    [ $# -eq 0 ] && { printf 'Usage: crc32rename <FILES>\n'; return 1; }
    command -v cksfv >/dev/null || { printf 'install cksfv\n'; return 1; }

    for i in "$@";do
        file -Lbi -- "$i" | grep -q '^video/' || { printf 'Not a video: %s\n' "$i"; continue; }
        crc=$(cksfv -b "$i" | sed '/^;/d; s/.*\(.\{8\}\)$/\1/')
        mv -vn "$i" "${i%.*} [${crc}].${i##*.}" || return 1
    done
}

chgrubbg() { # change grub background
    
    local image mime
    if [ -f "$1" ];then
        image="$1"
    elif [ -d "$1" ];then
        image=$(sxiv -qrto "$1" 2>/dev/null | head -1)
    else
        image=$(sxiv -qrto ~/Pictures/wallpapers 2>/dev/null | head -1)
    fi
    mime=$(file -Lbi -- "$image" | cut -d';' -f1)
    case "$mime" in
        image/jpeg) sudo convert -verbose "$image" /usr/share/desktop-base/active-theme/grub/grub-16x9.png ;;
        image/png)  sudo cp -v "$image" /usr/share/desktop-base/active-theme/grub/grub-16x9.png ;;
        *) return 1 ;;
    esac
}

dul() {
    # Output:
    #   size  | files | <filename>
    #   4.0K  |   0   | folder0/
    #   1.1M  |  18   | folder1/
    #   8.6M  |   2   | folder2/

    local size files
    printf '\033[42;30m%-8s | %-6s | %s\033[m\n' "size" "files" "filename"
    for i in */;do
        [ -d "$i" ] || continue
        size=$(du -sh "$i"  | awk '{print $1}')
        files=$(find "$i" -mindepth 1 -maxdepth 1 | wc -l)
        printf '%-8s | %-6s | %s\n' "$size" "$files" "$i"
    done | sort -h
}

fixext() {
    local mimetype ext
    [ $# -eq 0 ] && set -- ./*
    for i in "$@";do
        mimetype=$(file -Lbi -- "$i")
        case "${mimetype%;*}" in
            application/zip)  ext=zip ;;
            video/x-msvideo)  ext=avi ;;
            video/x-matroska) ext=mkv ;;
            video/mp4)        ext=mp4 ;;
            video/x-m4v)      ext=m4v ;;
            image/jpeg)       ext=jpg ;;
            image/png)        ext=png ;;
            *) continue ;;
        esac
        fname=${i%.*}
        fname=${fname:-$i}.${ext}
        [ "${i##*.}" != "$ext" ] && mv -vn -- "$i" "$fname"
    done
    return 0
}

odr() {
    # modified from r/opendirectories
    # download files from unprotected directories 
    case "$1" in
        video) set -- "$2" -A mkv,mp4,avi,mov,qt,wmv,divx,flv,vob ;;
        image) set -- "$2" -A jpg,jpeg,gif,png,tiff,bmp,svg ;;
        audio) set -- "$2" -A mp3,opus,flac,wav ;;
        http*) set -- "$1" ;;
    esac
    wget "$@" -w 3 -r -nc --no-parent --no-check-certificate \
           -U Mozilla/5.0 -l 200 -e robots=off -R "index.html*" -x
}

grabindex() { wget  -e robots=off -r -k -nv -nH -l inf -R --reject-regex '(.*)\?(.*)' --no-parent "$1" ; }

save_page() {
    wget -e robots=off --random-wait --adjust-extension \
        --span-hosts --convert-links --backup-converted \
        --no-parent --page-requisites -U Mozilla/5.0 "$1" 
}

trackers_best() {
    local url output
    url=https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt
    output=~/.cache/trackers_best.txt
    curl -s "$url" | grep --color=never '[a-z]' | tee "$output"
    xclip -sel clip -i "$output" 
}

random_img() {
    find "${@:-$HOME/Pictures/random}" -iname '*.jpg' -print0 |
        shuf -zn1 | xargs -0roI{} drawimg.sh '{}'
}

mvbyext() {
    find "${1:-.}" -maxdepth 1 -type f | while read -r i;do
        ext="${i##*.}"
        [ -z "$ext" ] || [ "${#ext}" -gt 4 ] && continue
        [ -d "$ext" ] || mkdir -v "$ext"
        mv -vn -- "$i" "$ext"
    done
}

mkj() { # Usage: `mkj *.mkv`
    for i in "$@";do
        mkvmerge -J "$i" | jq -r '.tracks[] |
"\(.type): \(.id) - \(.codec) - \(.properties.language) - \(.properties.track_name) \(
if .properties.default_track then "(default)" else "" end)"'
    done
}

random_str() {
    local chr n
    while (($#));do
        if [[ "$1" =~ ^[0-9]+$ ]];then n=$1 ;else chr=$1 ;fi
        shift
    done
    chr=${chr:-a-zA-Z0-9@!<>&%\$#_\\-\\.}
    tr -dc "$chr" < /dev/urandom | fold -w "${n:-10}" | head -1
    # shuf -er -n8 {A..Z} {a..z} {0..9} | tr -d '\n'
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
    value=$(<"$target")
    case "$value" in
        1) echo 0 ;;
        0) echo 1 ;;
    esac | sudo tee "$target"
}

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
        awk '{print} END {printf("%s unessential packages installed\n", NR)}' 
}

ffstr() { # Usage: `ffstr <video>`
    for i in "$@";do
        [ -f "$i" ] || continue
        [ "$#" -gt 1 ] && printf 'File: \e[1;35m%s\e[m\n' "$i"
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
    [ -b "$1" ] || set -- "$(df --output=source . | tail -1)"
    sudo tune2fs -l "$1" | awk -F':' '{
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

pyquote() {  # `quote/dequote` is already used by bash-completion :/
    python3 -c 'print(__import__("urllib.parse").parse.quote("\n".join(__import__("sys").stdin).strip() ))'
}

unquote() {
    python3 -c 'print(__import__("urllib.parse").parse.unquote("\n".join(__import__("sys").stdin).strip()))'
}

pyescape() {
    python3 -c 'print(__import__("html").escape("\n".join(__import__("sys").stdin).strip()))'
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
        e*) [ -s "$TODOFILE" ] && "${EDITOR:-vi}" "$TODOFILE" ;;
        l*) [ -s "$TODOFILE" ] && { printf >&2 '\e[1;30;43m TODO \033[m\n'; cat "$TODOFILE"; echo; } ;;
        r*)
            if [ -s "$TODOFILE" ]; then
                nl "$TODOFILE"
                read -r -p "1,2...: " n
                [[ "$n" =~ ^[0-9,]+$ ]] && sed -i "${n}d" "$TODOFILE"
            fi
        ;;
        a*)
            shift
            [ -n "$1" ] && printf '%s: %s\n' "$(date +'%Y.%m.%d %H:%M')" "$*" | tee -a "$TODOFILE"
        ;;
        *) echo 'Usage: todo <a|e|l|r> <TODO>' ;;
    esac
}

ftext() {
    # find text files
    find "${@:-.}" -type f -exec file -Li -- '{}' + | grep -oP '.*(?=:[\t ]*text/)'
}

paclog() {
    awk -v x="${1:-upgraded}" '$3 == x' /var/log/pacman.log |
    tac | awk -F'T' -v n=${2:-4} '{
        if ( substr($1, length($1)-1) != x && x) {
            c += 1
            if (c >= n)
                exit
            print "---"
        }
        print $0
        x = substr($1, length($1)-1)
    }' | tac
}

random_quote() { curl -s http://metaphorpsum.com/sentences/1; echo; }
random_anime_quote() {
    # Default rate limit is 100 requests per hour.
    local url="https://animechan.vercel.app/api/random"
    curl -s "$url" | jq -Mc '"\(.anime)\n\"\(.quote)\" - \(.character)"'
}

random_notepadpp_quote() {
    # parsed from https://github.com/notepad-plus-plus/notepad-plus-plus/blob/master/PowerEditor/src/Notepad_plus.cpp#L7103
    local target=~/.cache/notepadpp_quotes.txt
    shuf -n1 "$target" | awk -F':' '{
        a=$1; $1="";
        sub(/^ +/, "", $0);
        gsub(/\\n/, "\n");
        gsub(/\\"/, "\"");
        printf("%s\n\t- %s\n", $0, a);
    }'
}

random_color() {
    find ~/.scripts/playground/shell/Colors \
        -maxdepth 1 -type f -print0 | shuf -zn 1 | xargs -r0 bash
    printf '\e[0m'
}

grep_secrets() {
    # (\d{1,3}\.){3}\d+ IP
    grep --exclude-dir=".git" --color -rniP \
        'api.key|secret|token|password|passwd'
}

ordinal() {
    [[ "$1" =~ ^[0-9]+$ ]] || return 1
    curl -s "https://conversor-de-medidas.com/mis/numero-ordinal/_$1_" | tr -d \\n |
        grep -oP "(?<=>)[^<]* \($1.\)"
}

toggle_conservation_mode() {
    local v
    v=$(</sys/bus/platform/drivers/ideapad_acpi/VPC*/conservation_mode)
    [ $v -eq 0 ] && v=1 || v=0
    echo "$v" | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC*/conservation_mode
}

maldir() {
    local out 
    out=/tmp/.mal.$$
    mal "$@" | tee "$out" | grep -v ^http | fzf -m | grep -oP '.*\d{4}\)(?=\s+\| \w)' | while read -r i
    do
        [ -d "$i" ] || mkdir -v "./$i"
    done
    cat "$out"; command rm "$out"
}

qrcode() {
    local output
    output=$(mktemp -u /tmp/tmp.XXXXXXXX.png)
    sleep 1 ; scrot -s -q 100 "$output"
    zbarimg "$output"
    [ -f "$output" ] && rm "$output"
}

gamefaq() {
    # Example: gamefaq https://gamefaqs.gamespot.com/psp/955342-harvest-moon-hero-of-leaf-valley/faqs/59752
    curl -s "$1" | sed -n '/id="faqtext">/,$p' | tail -n +2 | sed '/<\/pre><\/div>/q' | head -n -2 | "$PAGER"
}

mvff() {
    # Move files listed on a text file ($1) to a directory ($2)
    file -Lbi "$1" | grep -q ^text/plain || return 1
    [ -d "$2" ] || return 1
    while read -r i;do mv -vn "$i" "$2" || break ;done < "$1"
}

downloadarch() {
    curl -s 'https://archlinux.org/download/' | grep -oP '(?<=href=")magnet:.*\.iso(?=")' | aria2c --input-file=-
}

translate() {
    # Usage: translate <phrase> <output-language> 
    # Example: translate "Bonjour! Ca va?" en 
    #
    # See this for a list of language codes: 
    # http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
    local query
    query=$(echo -n "$1" | sed "s/[\"'<>]//g")
    wget -U "Mozilla/5.0" -qO - "http://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$2&dt=t&q=$query" |
        sed "s/,,,0]],,.*//g" | awk -F'"' '{print $2, $6}'
}

howin() {
    # Use curl and "https://cht.sh/" to quickly search how to do things
    # Examples: 'howin html do I view an image'
    #           'howin python do I add numbers'
    local where q
    where="$1"; shift
    q=$* q=${q// /+}
    curl "https://cht.sh/$where/$q"
}

optimg() {
    # Potentially lower an image's file size using ImageMagick by lowering
    # the amount of colors, using dithering, increasing contrast, etc...
    # 
    #     Usage: optimg '/path/to/image.ext'
    # 
    convert "$1" -dither FloydSteinberg -colors 256 \
        -morphology Thicken:0.5 '3x1+0+0:1,0,0' \
        -remap netscape: -ordered-dither o8x8,6 +contrast "$1_converted"
}

optpdf() {
    # Potentially lower a PDF's file size using Ghostscript
    # 
    #     Usage: optpdf '/path/to/file.pdf'
    # 
    gs -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 \
        -dPDFSETTINGS=/screen -sOutputFile="${1%%.*}_small.pdf" "$1"
}

optgif() { 
    #Potentially lower an animated GIF's (89a) file size using gifsicle
    #
    #    Usage: optgif input.gif output.gif
    #
    gifsicle -i "$1" -O3 -o "$2"
}

vmrss() {
    ps -o rss -o comm "${1:-$!}" | awk '{if(!getline) exit 1; printf("%s MB\t%s\n", $1 / 1000, $2)}'
}

isup() {
    if hash wget 2>/dev/null; then
        wget -U Mozilla/5.0 -q --spider --server-response "$1" 2>&1
    elif hash curl 2>/dev/null; then
        curl -L -s --head --request GET "$1"
    fi
}

tsxiv() {
    find . -maxdepth 3 -type f -iregex '.*\.\(jpe?g\|png\)' -printf '%C@\t%p\n' |
        sort -rn | cut -f2- | sxiv -qi
}

tmpv() {
    find . -maxdepth 3 -type f -iregex '.*\.\(mkv\|mp4\|mov\|webm\|avi\|m4v\|gif\)' -printf '%C@\t%p\n' |
        sort -rn | cut -f2- | mpv --playlist=-
}

truecolor_test() {
    # https://github.com/termstandard/colors
    awk 'BEGIN{
        s="/\\/\\/\\/\\/\\"; s=s s s s s s s s;
        for (colnum = 0; colnum<77; colnum++) {
            r = 255-(colnum*255/76);
            g = (colnum*510/76);
            b = (colnum*255/76);
            if (g>255) g = 510-g;
            printf "\033[48;2;%d;%d;%dm", r,g,b;
            printf "\033[38;2;%d;%d;%dm", 255-r,255-g,255-b;
            printf "%s\033[0m", substr(s,colnum+1,1);
        }
        printf "\n";
    }'
}


colors() {
    # Output predominant colors in a image
    file -Lib "$1"| grep -q ^image || return 1;
    magick "$1" -scale 50x50\! -depth 8 +dither -colors 8 -format "%c" histogram:info: | sort -rn |
        awk '{
        hex = $3
        match($2, /\(([0-9\.]+),([0-9\.]+),([0-9\.]+)/, rgb)
        r = rgb[1]
        g = rgb[2]
        b = rgb[3]
        if (g>255) g = 510-g;
        printf "\033[48;2;%d;%d;%dm %8s %8s %8s", r,g,b,r,g,b;
        printf "\033[38;2;%d;%d;%dm", 255-r,255-g,255-b;
        printf "\033[0m %s\n", hex;
        }'
}

cleanup_apps() {
    grep -rn '^Exec=' ~/.local/share/applications/ ~/Desktop/ 2>/dev/null | while read -r i
    do
        file=${i%.desktop:*}.desktop
        cmd=${i##*:Exec=} cmd=${cmd%% *}
        if ! [ -x "$cmd" ] && ! command -v "$cmd" >/dev/null 2>&1;then
            printf '\033[1;31m%s\033[m not found\n' "$cmd"
            [ -f "$file" ] && rm -vi "$file" </dev/tty
        fi
    done
}

magnet() {
    curl -s --user-agent "$UserAgent" "$1" |
        sed 's/<.\?br>//g; s/\&amp;/\&/g'  |
        grep -oP 'magnet:\?xt=urn:[A-z0-9]+:[A-z0-9]+(?=&dn=)' |
        aria2c --file-allocation=none --bt-save-metadata --bt-metadata-only --input-file=-
}

zipdir() {
    local out
    out=$(realpath "$1").zip
    [ -d "$1" ] && zip -r -v -1 "${out}" "$1"
}

allowit() {
    find "${@:-.}" -type f -exec chmod -c g+r {} +
    find "${@:-.}" -type d -exec chmod -c g+rwx {} +
}

bak() {
    command cp -vn "$1" "${1}.bak"
}

clipw() {
    local c out
    out="${1:-clipboard.txt}"
    touch "$out"
    while sleep .2;do 
        # c=$(wl-paste)
        c=$(xclip -o -rmlastnl 2>/dev/null)
        grep -qxF "$c" "$out" || echo "$c"
    done | tee -a "$out"
}


n() {
    if [ -n "$NNNLVL" ] && [ "${NNNLVL:-0}" -ge 1 ]; then
        echo "nnn is already running"; return
    fi
    export NNN_TMPFILE="$HOME/.config/nnn/.lastd"

    nnn "$@"

    if [ -f "$NNN_TMPFILE" ]; then
        # shellcheck disable=SC1090
        . "$NNN_TMPFILE"
        command rm -f "$NNN_TMPFILE"
    fi
}

r() {
    local cache=~/.cache/.rangedir
    ranger --choosedir="$cache" "$@"
    cd -- "$(cat "$cache")" || return 1
}

hxsj() {
    # mappings for the hxsj keyboard
    setxkbmap -layout us -variant altgr-intl
    xmodmap -e "keycode  24 = q Q NoSymbol NoSymbol slash"
    xmodmap -e "keycode  25 = w W NoSymbol NoSymbol question"
    xmodmap -e "keycode  34 = backslash bar"
    xmodmap -e "keycode  35 = bracketleft braceleft"
    xmodmap -e "keycode  47 = asciitilde asciicircum"
    xmodmap -e "keycode  51 = bracketright braceright"
    xmodmap -e "keycode  61 = semicolon colon"
}

fixkbd() {
    setxkbmap br
    # localectl list-x11-keymap-options
    # xmodmap -e "keycode 108 = Alt_L" # Alt_Gr
    xmodmap -e "keycode 97 = Alt_L" # backslash
    xmodmap -e "keycode 34 = dead_grave backslash" # dead_acute 
    xmodmap -e "keycode 47 = asciitilde bar" # ccedilla
    xmodmap -e "keycode 26 = e E NoSymbol NoSymbol g"
    xmodmap -e "keycode 27 = r R NoSymbol NoSymbol h"
    xmodmap -e "keycode 28 = t T NoSymbol NoSymbol Up"
    # xmodmap -e "keycode 73 = g" # F7
    # xmodmap -e "keycode 74 = h" # F8
    # xmodmap -e "keycode 15 = 6 backslash"  # dead_diaeresis
    # xmodmap -e "keycode 81 = bar backslash " # KP_Prior (9)
    # xmodmap -e "keycode 91 = asciitilde"  # KP_Delete
}

convert_functions_to_scripts() {
    local functions_dir script
    functions_dir=~/.scripts/shell/functions
    mkdir -vp "$functions_dir"
    # `declare -F`
    grep -oP '^[a-z0-9][a-z0-9_]+?(?=\(\) {)' ~/.scripts/shell/{mediainfo,fzf,aria2,functions}.sh  | while IFS=: read -r path function_name
    do
        script=${functions_dir}/${function_name}
        [ -s "$script" ] && command rm "${script}"
        type "$function_name" | while IFS= read -r l
        do
            if [[ "$l" =~ "is a function"$ ]];then
                echo "#!/usr/bin/env bash" >> "${script}"
                continue
            fi
            [ -s "$script" ] || break
            echo "$l" >> "$script"
        done
        printf '%s $@\n' "${function_name}" >> "$script"
        chmod +x "$script"
    done
}

pfx() {
    if [ -d "$1" ];then
        export WINEPREFIX=$(realpath "$1")
        printf '\nwine prefix changed to \033[1;33m%s\033[m\n' "${WINEPREFIX}"
    else
        echo "$WINEPREFIX"
    fi
}

get_cursor_pos() {
    local c r
    IFS='[;' read -p $'\e[6n' -d R -rs _ r c _ _
    echo "row $r column $c"
}
