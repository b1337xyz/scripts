#!/usr/bin/env bash
command -v aria2c &>/dev/null || { printf 'install aria2\n'; exit 1; }

scape_ptr() {
    ptr=${1//\[/\\[}  ptr=${ptr//\]/\\]}
    ptr=${ptr//\*/\\*}  ptr=${ptr//\$/\\$}
    ptr=${ptr//\?/\\?}   
    printf '%s\n' "$ptr"
}

file -Lbi -- "$1" | grep -q bittorrent || exit 1
torrent=$1
torrent_name=$(aria2c -S "$torrent" | awk -F'/' '/ 1\|\.\//{print $2}')
new_torrent=${torrent_name}.torrent
[ "$new_torrent" != "$torrent" ] && cp -nv "$torrent" "$new_torrent"

aria2c -S "$torrent" | awk -F'|' '/[0-9]\|\.\//{print $2}' | while read -r i;do
    ptr=$(scape_ptr "${i##*/}")
    f=$(find . -type f -name "$ptr") 
    [ -z "$f" ] && { printf '\e[1;31m:(\e[m %s\n' "$f"; exit 1; }
    printf '\e[1;32m:)\e[m %s\n' "$f"
done

aria2c -S "$torrent" | awk -F'|' '/[0-9]\|\.\//{print $2}' | while read -r i;do
    d="${i%/*}"
    if [[ "$d" =~ \.(mkv|avi|mp4|rmvb)$ ]];then
        d=
    else
        [ -d "$d" ] || mkdir -pv "$d"
    fi

    ptr=$(scape_ptr "${i##*/}")
    f=$(find . -type f -name "$ptr") 
    if [ -f "$f" ];then
        mv -nv "$f" "$d"
    else
        printf '%s not found!\n' "${i##*/}"
    fi
done
