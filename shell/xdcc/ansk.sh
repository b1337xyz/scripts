#!/usr/bin/env bash
set -e

tmpfile=$(mktemp)
end() { rm "$tmpfile"; }
trap end EXIT

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

packs=
old_bot=
if [ $# -gt 0 ];then
    q=$*
    search "${q// /+}"
else
    latest
fi | sed 's/\/msg ANSK|\(.*\) xdcc send #\([0-9]*\) \(.*\)/\1 \2 \3/' |
     tee "$tmpfile" | fzf -m | awk '{print $1" "$2}' | sort | while read -r bot pack
do
    packs+="${pack},"
    [ -z "$old_bot" ] && old_bot=$bot
    if [ "$bot" != "$old_bot" ];then
        old_bot=$bot
        xdcc -s irc.rizon.net -c '#AnimeNSK' "ANSK|${bot}" send "${packs::-1}" 
        sleep 10
        packs=
    fi
done
