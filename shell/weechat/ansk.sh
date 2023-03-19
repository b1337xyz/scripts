#!/usr/bin/env bash
set -e

tmpdir=~/tmp
FIFO=$(find /run/user/1000/weechat/ -type p)
[ -z "$FIFO" ] && { echo "$FIFO not found"; exit 1; }
pgrep -x weechat || exit 1

search() {
    curl -s "https://packs.ansktracker.net/index.php?Modo=Busca&find=$1" | pup '.L1 json{}' |
    jq -r '.[] | "\(.children[3].children[0].text) \(.children[4].text)"'
}
latest() {
    curl -s "https://packs.ansktracker.net" | pup '.L2 json{}' |
    jq -r '.[] | "\(.children[2].children[0].text) \(.children[0].text) \(.children[1].text)"'
}

if [ $# -gt 0 ];then
    q=$*
    search "${q// /+}"
else
    latest
fi | sed 's/\/msg ANSK|\(.*\) xdcc send #\([0-9]*\) \(.*\)/\3|\1|\2/' |
    fzf -m | awk -F'|' '{print $2" "$3}' | while read -r bot pack
do
    echo "irc.rizon.#AnimeNSK */msg ANSK|$bot xdcc send #$pack" > "$FIFO"
    sleep 5
    while :;do
        out=$(find "$tmpdir" -type f -name '*.part')
        [ -z "$out" ] && break
        sleep 1
    done
    find "$tmpdir" -type f ! -name '*.part' \
        \( -exec scp '{}' arch:Downloads \; -a -exec rm -v {} + \)
done
