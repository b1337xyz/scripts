#!/usr/bin/env bash
set -e

WALL_DIR=~/Pictures/WallHaven
[ -z "$WALLHAVEN_API_KEY" ] && exit 1

if [[ "$1" =~ ^- ]];then
    cat << EOF
Usage: ${0##*/} <query>
    tagname         - search fuzzily for a tag/keyword
    -tagname        - exclude a tag/keyword
    +tag1 +tag2     - must have tag1 and tag2
    +tag1 -tag2     - must have tag1 and NOT tag2
    @username       - user uploads
    id:123          - Exact tag search (can not be combined)
    type:{png/jpg}  - Search for file type (jpg = jpeg)
    like:wallpaper  - Find wallpapers with similar tags
EOF
    exit 0
fi

search() {
    q=${1// /\+}
    url="https://wallhaven.cc/api/v1/search?apikey=${WALLHAVEN_API_KEY}&q=${q}&page=${2:-1}"
    curl -s "$url"
}

if [ $# -gt 0 ];then
    page=1
    last_page=$(search "$*" | jq -r .meta.last_page)
    while [ "$page" -lt "$last_page" ];do
        echo "[${page}/${last_page}] $*" >&2
        search "$*" "$page" | jq -r '.data[].path'
        ((page++))
    done | xargs -rP3 wget -nc -P "$WALL_DIR"
fi
