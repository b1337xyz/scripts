#!/bin/sh
set -ex
FIFO=$(find /run/user/1000/weechat -type p)
cache=~/.cache/ansk
tmpdir=~/tmp

[ -z "$FIFO" ] && { echo "$FIFO not found"; exit 1; }
pgrep -x weechat || exit 1

curl -s "https://packs.ansktracker.net"     |
grep -oP '/msg ANSK\|\w* xdcc send #\d*'    |
while read -r msg;do
    if ! grep -qxF "$msg" "$cache" 2>/dev/null;then
        echo "irc.rizon.#AnimeNSK *${msg}" > "$FIFO"
        echo "$msg" | tee -a "$cache"
        sleep 10
        f=$(find "$tmpdir" -type f -name '*.part')
        echo "Downloading... $f"
        while [ -f "$f" ];do
            sleep 1
        done
        find "$tmpdir" -type f ! -name '*.part' \
            \( -exec scp {} arch:Downloads \; -a -exec rm -v {} \; \)
    fi
done
