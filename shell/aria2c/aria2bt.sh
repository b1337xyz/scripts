#!/usr/bin/env bash
set -eo pipefail
command -v aria2c &>/dev/null || { printf 'install aria2\n'; exit 1; }

PID=$$
MAX_TORRENTS=4
QUEUE=~/.config/aria2/bt-queue
LOG=~/.config/aria2/bt-log
CACHE=~/.cache/torrents
COMPLETE_TORRENTS="$HOME/Downloads"
INCOMPLETE_TORRENTS="$HOME/Downloads/.torrents"
ERROR_DIR="${INCOMPLETE_TORRENTS}/.error"
TIMEOUT=$(( 60 * 15 )) # minutes

echo "$(date +%Y-%m-%d\ %H:%M:%S): $*" >> "$LOG"
echo "$PID" >> "$QUEUE"
end() { sed -i "/$PID/d" "$QUEUE"; }
trap end EXIT

notify() { dunstify -r "$PID" -t 3000 -i emblem-downloads "$@"; }

q=$(wc -l < $QUEUE)
if [ "$q" -gt "$MAX_TORRENTS" ];then
    n=$(grep -n "$PID" "$QUEUE" | cut -d':' -f1)
    notify "torrent in queue ($n)" "please wait...\n$1"
    echo "please wait..."

    while :;do
        head -n "$MAX_TORRENTS" "$QUEUE" | grep -qx "$PID" && break
        sleep 5
    done
fi

[ -d "$CACHE" ] || mkdir -v "$CACHE"
[ -d "$INCOMPLETE_TORRENTS" ] || mkdir -vp "$INCOMPLETE_TORRENTS"
[ -d "$ERROR_DIR" ] || mkdir -v "$ERROR_DIR"

torrent=$1
if [[ "$torrent" =~ ^magnet: ]];then
    notify "torrent added" "saving metadata...\n$torrent"
    printf "saving torrent metadata...\n"

    tmpdir=$(mktemp -d)
    if ! aria2c -q --bt-stop-timeout=$TIMEOUT --bt-save-metadata --bt-metadata-only \
        -d "$tmpdir" "$torrent"
    then
        rm -rf "$tmpdir"
        notify "failed to save metadata"
        exit 1
    fi
    torrent=$(find "$tmpdir" -type f)
fi

file -bi "$torrent" | grep -q bittorrent || exit 1

torrent_name=$(aria2c -S "$torrent" | awk -F'/' '/ 1\|\.\//{print $2}')
torrent_size=$(aria2c -S "$torrent" | awk '/^Total/{print}')
torrent_path="${INCOMPLETE_TORRENTS}/${torrent_name}.torrent"
mv -vn "$torrent" "$torrent_path"
[ -d "$tmpdir" ] && rm -rf "$tmpdir"

printf '\033]2;%s\007' "$torrent_name"
notify "torrent started" "Name: ${torrent_name}\n${torrent_size}"
printf '>>> %s\n>>> %s\n' "$torrent_name" "$torrent_size"

sleep 10

if aria2c --bt-stop-timeout=$TIMEOUT -d "$INCOMPLETE_TORRENTS" "$torrent_path";then
    notify "torrent completed" "${torrent_name}\n${torrent_size}"
    mv -vn "${INCOMPLETE_TORRENTS}/${torrent_name}" "$COMPLETE_TORRENTS"
    mv -vf "$torrent_path" "$CACHE"
    exit 0
else
    notify "$torrent_name" "finished with errors"
    mv -vf "$torrent_path" "$ERROR_DIR"
    exit 1
fi
