#!/usr/bin/env bash

set -e

declare -r -x TRASH_DIR=~/.local/share/mytrash/files
declare -r -x TRASH_INFO=~/.local/share/mytrash/info
declare -r -x TRASH_LOG=${TRASH_INFO}/log
[ -d "$TRASH_DIR" ] || { mkdir -p "$TRASH_DIR" || exit 1; }
[ -d "$TRASH_INFO" ] || { mkdir -p "$TRASH_INFO" || exit 1; }

usage() {
    printf 'Usage: %s [-r INT] [-fr] [-f] [-l] FILE\n' "${0##*/}"
    echo "$@"
    exit 1
}
trash_list() {
    local _date fname rpath l
    #awk -F'|' '{printf("%s\n%s\n%s\n", $1, $2, $3)}' "$TRASH_INFO"
    l=1
    while IFS='|' read -r _date fname rpath;do
        printf '\e[1;31m%s\e[m: \e[1;32m%s\e[m\n' "$l" "$_date"
        printf 'Trash: %s\nOrigin: %s\n' "$fname" "$rpath"
        (( l += 1 ))
    done < "$TRASH_LOG" #2>/dev/null
}
update_log() {
    local tmpfile l
    if [ -f "$TRASH_LOG" ];then
        tmpfile=$(mktemp)
        cp "$TRASH_LOG" "$tmpfile"
        l=1
        while IFS='|' read -r _ fname _;do
            [ -f "${TRASH_DIR}/${fname}" ] ||
                sed -i "${l}d" "$TRASH_LOG" 
            (( l += 1 ))
        done < "$tmpfile"

        rm -f "$tmpfile"
    fi
}
update_log
preview() {
    local _date fname rpath l
    IFS='|' read -r _date fname rpath < <(grep -F "|${1}|" "$TRASH_LOG")
    l=$(grep -nF "|$1|" "$TRASH_LOG" | cut -d':' -f1)
    printf '\e[1;31m%s\e[m: \e[1;32m%s\e[m\n' "$l" "$_date"
    printf 'Trash: %s\nOrigin: %s\n' "$fname" "$rpath"
}
export -f preview
find_trash() {
    awk -F'|' '{print $2}' "$TRASH_LOG" |
        fzf --preview 'preview {}' --preview-window 'bottom:20%'
}
restore() {
    if [ "$1" = "-fr" ];then
        fname=$(find_trash)
        [ -z "$fname" ] && exit 1
        n=$(grep -nF "|$fname|" "$TRASH_LOG")
        n=${n%%:*}
    elif [[ "$2" =~ ^[1-9]*$ ]];then
        n="$2"
    else
        trash_list
        read -r -p ': ' n
    fi
    [[ "$n" =~ ^[1-9]*$ ]] || usage "Invalid range"
    [[ "$n" -le "$(wc -l "$TRASH_LOG" | cut -d' ' -f1)" ]] || usage
    IFS='|' read -r _date fname rpath < <(sed "${n}!d" "$TRASH_LOG")
    src="${TRASH_DIR}/${fname}"
    if [ -d "${rpath%/*}" ];then
        dst="${rpath%/*}/$fname"
        [ -f "$dst" ] && dst="${rpath%/*}/from_trash_$fname"
    else
        dst="$PWD/$fname" 
        [ -f "$dst" ] && dst="${PWD}/from_trash_$fname"
    fi
    c=0
    while [ -f "$dst" ];do
        new_dst="${dst%/*}/${c}_$fname"
        [ -f "$new_dst" ] || { dst=$new_dst; break; }
        (( c += 1 ))
    done
    mv -nv "$src" "$dst"
}

while [ $# -gt 0 ];do
    if [ -f "$1" ] && [ ! -h "$1" ];then
        fname="${1##*/}"
        rpath=$(realpath "$1")
        [ -z "$fname" ] && usage

        c=0
        while [ -e "${TRASH_DIR}/${fname}" ];do
            fname="${c}_${1##*/}"
            (( c += 1 ))
        done
        mv -nv "$1" "${TRASH_DIR}/${fname}"
        echo "$(date +%d-%m-%Y' '%H:%M:%S)|${fname}|${rpath}" >> "${TRASH_LOG}"
    else
        case "$1" in
            -l) trash_list ; break ;;
            -ls) ls -Ah --color=always "$TRASH_DIR" ; break ;;
            -f) find_trash ; break ;;
            -r|-fr) restore "$@" ; update_log ; break ;;
            *) usage ;;
        esac
    fi

    shift
done
