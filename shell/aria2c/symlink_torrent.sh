#!/usr/bin/env dash

set -e

SCRIPT="${0##*/}"
TORRENT_DIR=~/Downloads/torrents/Symlinks
TORRENT_DIR=$(echo "$TORRENT_DIR" | sed 's/\/$//g')

while [ $# -gt 0 ];do
    case "$1" in
        *.torrent) torrent=$1 ;;
        *) [ -d "$1" ] && target="$1" ;;
    esac
    shift
done
usage() { printf '%s <torrent file> <target directory>\n' "$SCRIPT"; exit 1; }
[ -f "$torrent" ] || usage
[ -z "$target" ] && usage

aria2c -S "$torrent" | awk -F'|' '/ 1\|\.\//{print substr($2, 3)}' | while read -r i;do
    d=${i%/*}
    [ "$d" = "$i" ] && continue
    mkdir -vp "${TORRENT_DIR}/${d}"
done

find_by_crc() {
    aria2c -S "$torrent" | awk -F'|' '/[0-9]\|\.\//{print substr($2, 3)}' | 
    while read -r i;do
        crc=$(echo -n "$i" |
            sed 's/[0-9]\{4\}x[0-9]\{3\}//g' |
            grep -oP '(\[|\()[[:alnum:]]{8}(\)|\])' | tail -1 |
            sed 's/\[/\\[/g; s/\]/\\]/g'
        )
        [ -z "$crc" ] && continue
        f=$(find "$target" -type f -iname "*${crc}*")
        [ -f "$f" ] || continue
        [ -h "${TORRENT_DIR}/$i" ] && continue
        ln -vrs "$f" "${TORRENT_DIR}/$i"
    done
}
find_by_files() {
    aria2c -S "$torrent" | awk -F'|' '/[0-9]\|\.\//{print substr($2, 3)}' | while read -r i
    do
        fname=$(echo -n "${i##*/}" | sed -e 's/[]\[?\*\$]/\\&/g')
        f=$(find "$target" -type f -name "$fname")
        [ -f "$f" ] || continue
        [ -h "${TORRENT_DIR}/${i%/*}/${f##*/}" ] && continue
        ln -vrs "$f" "${TORRENT_DIR}/${i%/*}"
    done
}
check_torrent() {
    aria2c -S "$torrent" | awk -F'|' '/[0-9]\|\.\//{print substr($2, 3)}' |
    while read -r i;do
        [ -h "${TORRENT_DIR}/${i}" ] || {
            printf '%s not found\n' "${TORRENT_DIR}/${i}";
            return 1;
        }
    done && {
        cp -v "$torrent" "$TORRENT_DIR";
        printf '\033[1;32mSuccess! :)\033[m\n'; 
        return 0;
    }
    return 1
}

printf 'Searching files...\n'
find_by_files
check_torrent && exit 0

printf 'Searching by crc32...\n'
find_by_crc
check_torrent && exit 0

exit 1
