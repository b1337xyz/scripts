#!/usr/bin/env bash
set -eo pipefail

tmpdir=~/tmp
FIFO=$(find /run/user/1000/weechat/ -type p)
[ -z "$FIFO" ] && { echo "$FIFO not found"; exit 1; }
pgrep -x weechat || exit 1

search() {
    # <tr class="L1">
    #   <td> pack number </td> children 0
    #   <td> gets number </td> children 1 
    #   <td> size </td> children 2 
    #   <td> children 3
    #       <pre> bot cmd </pre> children 3.0
    #   </td> 
    #   <td> title + info </td> children 4
    curl -s "https://packs.ansktracker.net/index.php?Modo=Busca&find=$1" | pup '.L1 json{}' |
    jq -r '.[] | "\(.children[3].children[0].text) \(.children[4].text)"'
}
latest() {
    # output = title tags|ANSK|bot|pack

    # <tr class="L2">
    #   <td> title </td> children 0
    #   <td> info  </td> children 1 
    #   <td>             children 2
    #       <pre> bot cmd </pre> children 2.0
    #   </td> children 
    #  /msg ANSK|BOT xdcc send #0000 title info
    curl -s "https://packs.ansktracker.net" | pup '.L2 json{}' |
    jq -r '.[] | "\(.children[2].children[0].text) \(.children[0].text) \(.children[1].text)"'
}

if [ $# -gt 0 ];then
    q=$*
    search "${q// /+}"
else
    latest
fi | sed 's/\/msg ANSK|\(.*\) xdcc send #\([0-9]*\) \(.*\)/\3|\1|\2/' |
    fzf -m | awk -F'|' '{print $2" "$3}' | while read bot pack
do
    echo "irc.rizon.#AnimeNSK */msg ANSK|$bot xdcc send #$pack" > "$FIFO"
    sleep 10
    f=$(find "$tmpdir" -type f -name '*.part')
    echo "Downloading... $f"
    while [ -f "$f" ];do
        sleep 1
    done
    find "$tmpdir" -type f ! -name '*.part' \
        \( -exec scp '{}' arch:Downloads \; -a -exec rm -v {} + \)
done
