# shellcheck disable=SC2046
# shellcheck disable=SC2086

VideoPattern='\.\(mkv\|webm\|flv\|ogv\|ogg\|avi\|ts\|mts\|m2ts\|mov\|wmv\|rmvb\|mp4\|m4v\|m4p\|mpg\|mpeg\|3gp\|gif\)$'
ImagePattern='\.\(jpg\|png\|jpeg\|bmp\|tiff\|svg\|gif\|webp\)$'
ArchivePattern='\.\(zip\|rar\|7z\|lzma\|gz\|xz\|tar\|bz2\|arj\)$'

f() { find . -xdev -iname "$*"; }
d() { du -had1 "${1:-.}" 2>/dev/null | sort -h; }
fox() { command firefox "$@" &>/dev/null & disown ; }
za() { command zathura "$@" &>/dev/null & disown ; }
wall() { awk -F'"' '{print $2}' ~/.cache/xwallpaper 2>/dev/null; }
lyrics() { while :;do clyrics -p -k -s 20 ; sleep 5 ;done; }
calc() { echo "scale=3;$*" | bc -l; }
start_xephyr() { Xephyr -br -ac -noreset -screen 800x600 :1; }
keys() { xev | awk -F'[ )]+' '/^KeyPress/ { a[NR+2] } NR in a { printf "%-3s %s\n", $5, $8 }'; }
upload() { curl -F"file=@$*" https://0x0.st | tee -a ~/.cache/0x0.st; }
uniq_lines() { awk '!seen[$0]++' "$1"; }
fext() { find . -type f -name '*\.*' | grep -o '[^\.]*$' | sort -u; }
fvideo() { find . -iregex ".*$VideoPattern"; }
fimage() { find . -iregex ".*$ImagePattern"; }
farchive() { find . -iregex ".*$ArchivePattern"; }
grep_video() { grep --color=never -i "$VideoPattern" "$1"; }
grep_image() { grep --color=never -i "$ImagePattern" "$1"; }
grep_archive() { grep --color=never -i "$ArchivePattern" "$1"; }
curlt() {
    # curl html as simple text (from WANDEX scripts-wndx)
    curl -s "$1" | sed 's/<\/*[^>]*>/ /g; s/&nbsp;/ /g';
}
histcount() {
    # Example: `histcount`
    # Output:
    #  ...
    #  185 git
    #  223 pacman
    #  411 vi
    #  441 sudo
    # 9969 neofetch
    HISTTIMEFORMAT='' history | sed 's/[\t ]*[0-9]\+[\t ]*\([^ ]*\).*/\1/' | sort | uniq -c | sort -n | tail
}
cpl() {
    # Example:
    #   cpl <file> 
    #   cd ~/Downloads
    #   cpl # <file> is copied to the current directory

    local cache=/tmp/.copy_later
    if [ -f "$1" ];then
        command rm "$cache" 2>/dev/null
        realpath -- "$@" >> "$cache"
    elif [ -f "$cache" ];then
        while read -r i;do
            [ -f "$i" ] && cp -vn "$i" .
        done < "$cache"
    else
        printf 'nothing to do\n'
    fi
}
arc() {
    # Archive file
    local filename basename archive
    shopt -s extglob
    filename=${1%%+(/)} # remove `///...` if present at the end of "$1" (requires extglob)
    shopt -u extglob
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
    # find repeated files
    find . -maxdepth "${1:-3}" -type f -printf '%f\n' | sort | uniq -d |
    sed -e 's/[]\[?\*\$]/\\&/g' | tr \\n \\0 | xargs -0rI{} find . -type f -name '{}'
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
        case "$mime" in
            image/gif*) continue ;;
            image/jpeg*)
                [ "${i##*.}" != "jpg" ] && mv -vn -- "$i" "${i%.*}.jpg" ;;
            image/*)
                convert -verbose "$i" "${i%.*}.jpg" && rm -v -- "$i" ;;
        esac
    done
}
ex() {
    # decompress stuff
    for i in "$@";do
        [ -f "$i" ] || return 1
        case "$i" in
            *.tar.zst) tar --zstd -xf "$i" ;;
            *.tar.bz2) tar xvjf "$i"   ;;
            *.tar.gz)  tar xvzf "$i"   ;;
            *.tar)     tar xvf "$i"    ;;
            *.bz2)     bunzip2 "$i"    ;;
            *.zst)     unzstd "$i"     ;;
            *.rar)     unrar x -op"${i%.*}" "$i" ;;
            *.zip)     unzip "$i" -d "${i%.*}"   ;;
            *.gz)      gunzip "$i"     ;;
            *.7z)      7z x "$i"       ;;
            *.Z)       uncompress "$i" ;;
        esac || return 1
    done
}
repeat() {
    # Repeat n times command
    local max=$1; shift;
    for ((i=1; i <= max ; i++)); do
        eval "$*";
    done
}
loop() {
    # loop a command for n seconds
    local s
    [[ "$1" =~ ^[0-9]+$ ]] && { s=$1; shift; }
    [ -z "$1" ] && { printf 'Usage: loop <seconds> <cmd...>\n'; return 1; }
    while :;do eval "$*"; sleep "${s:-15}"; done
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
    local tmpfile
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
bulkrename() {
    local tmpfile
    declare -f -a files=()
    tmpfile=$(mktemp)
    while IFS= read -r -d $'\0' i;do
        files+=("${i#*/}")
        printf '%s\n' "${i#*/}" >> "$tmpfile" 
    done < <(find . -mindepth 1 -maxdepth 1 \! -path '*/\.*' -print0 | sort -zV)

    [ "${#files[@]}" -eq 0 ] && return 1
    vim "$tmpfile"

    lines=$(wc -l < "$tmpfile")
    if [ "${#files[@]}" -ne "$lines" ];then
        printf 'The number of lines does not match the amount of files!'
        command rm "$tmpfile"
        return 1
    else
        i=0
        while read -r l;do
            [ -e "$l" ] || mv -vn -- "${files[i]}" "$l"
            ((i++))
        done < "$tmpfile"
    fi
    command rm "$tmpfile"
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
crc32rename() {
    # add [<crc32>] to the filename

    [ $# -eq 0 ] && { printf 'Usage: crc32rename <FILES>\n'; return 1; }
    command -v cksfv >/dev/null || { printf 'install cksfv\n'; return 1; }

    for i in "$@";do
        file -Lbi -- "$i" | grep -q '^video/' || { printf 'Not a video: %s\n' "$i"; continue; }
        crc=$(cksfv -b "$i" | sed '/^;/d; s/.*\(.\{8\}\)$/\1/')
        mv -vn "$i" "${i%.*} [${crc}].${i##*.}" || return 1
    done
}
chgrubbg() {
    # change grub background
    
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
dn() {
    # top n biggest files
    find . -mindepth 1 -maxdepth 1 -exec du -sh {} + |
        sort -h | head -n "${1:-10}" | awk -F\\t '{print $2}' |
        tr \\n \\0 | du --files0-from=- -csh | sort -h
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
           -U mozilla -l 200 -e robots=off -R "index.html*" -x
}
save_page() {
    wget -e robots=off --random-wait --adjust-extension \
        --span-hosts --convert-links --backup-converted \
        --no-parent --page-requisites -U mozilla "$1" 
}
edalt() {
    # edit the current alacritty theme
    awk -v home="$HOME" '/\/themes\//{sub("~", home, $2); printf("%s\0", $2)}' \
        ~/.config/alacritty/alacritty.yml | xargs -0roI{} vim '{}'
}
magrep() {
    # grep magnet links
    [ -z "$1" ] && { printf 'Usage: magrep <url>\n'; return 1; }
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
mkj() {
    # Usage: `mkj video.mkv`
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
ffstr() {
    # Usage: `ffstr <video>`
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
    [ -b "$1" ] || return 1
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
quote() {
    python3 -c 'print(__import__("urllib.parse").parse.quote(("\n".join(__import__("sys").stdin).strip())))'
}
unquote() {
    python3 -c 'print(__import__("urllib.parse").parse.unquote(("\n".join(__import__("sys").stdin).strip())))'
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
        e*) [ -s "$TODOFILE" ] && "${EDITOR:-vim}" "$TODOFILE" ;;
        l*)
            if test -s "$TODOFILE";then
                printf '\n\e[1;30;43m TODO \033[m\n'
                cat "$TODOFILE"; echo
            fi
        ;;
        r*)
            nl "$TODOFILE"
            read -r -p ": " n
            [[ "$n" =~ ^[0-9]+$ ]] && sed -i "${n}d" "$TODOFILE"
        ;;
        a*)
            shift
            [ -n "$1" ] && printf '%s: %s\n' \
                "$(date +'%Y.%m.%d %H:%M')" "$*" | tee -a "$TODOFILE"
        ;;
        *) echo 'Usage: todo [ed ls rm add] <TODO>' ;;
    esac
}
ftext() {
    # find text files
    find "${@:-.}" -type f -exec file -Li -- '{}' + | grep -oP '.*(?=:[\t ]*text/)'
    return 0
}
paclog() {
    awk -v x="${1:-upgraded}" '$3 == x' /var/log/pacman.log |
    tac | awk -F'T' -v n=4 '{
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
    clear
    find ~/.scripts/playground/shell/Colors \
        -maxdepth 1 -type f -print0 | shuf -zn 1 | xargs -r0 bash
    printf '\e[0m'
}
grep_secrets() {
    grep --exclude-dir=".git" --color -rniP \
        'api.key|secret|token|password|passwd|(\d{1,3}\.){3}\d+'
}
ordinal() {
    [[ "$1" =~ ^[0-9]+$ ]] || return 1
    curl -s "https://conversor-de-medidas.com/mis/numero-ordinal/_$1_" | tr -d \\n |
        grep -oP "(?<=>)[^<]* \($1.\)"
}
enable_conservation_mode() {
    echo "${1:-1}" | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC*/conservation_mode
}
maldir() {
    out=/tmp/.mal.$$
    mal "$@" | tee "$out" | grep -v ^http | fzf -m | grep -oP '.*\d{4}\)(?=\s+\| \w)' | while read -r i
    do
        [ -d "$i" ] || mkdir -v "./$i"
    done
    cat "$out"; command rm "$out"
}
qrcode() {
    output=$(mktemp -u /tmp/tmp.XXXXXXXX.png)
    sleep 1 ; scrot -s -q 100 "$output"
    zbarimg "$output"
    [ -f "$output" ] && rm "$output"
}
