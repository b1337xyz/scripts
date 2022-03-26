#!/usr/bin/env bash
command -v pup &>/dev/null || { printf 'install pup\n'; return 1; }
command -v xdcc &>/dev/null || { printf 'install xdcc\n'; return 1; }
command -v jq &>/dev/null || { printf 'install jq\n'; return 1; }
command -v fzf &>/dev/null || { printf 'install fzf\n'; return 1; }

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

# output = title tags|ANSK|bot|pack
if [ -n "$1" ];then
    search "$1"
else
    latest
fi | sed 's/\/msg ANSK|\(.*\) xdcc send #\([0-9]*\) \(.*\)/\1|\2|\3/' |
     tee "$tmpfile" | awk -F'|' '{print $3}' | fzf -m | while read -r i;do
        read -r bot pack < <(grep -F "|$i" "$tmpfile" | awk -F'|' '{print $1" "$2}')
        [ -z "$pack" ] && break
        xdcc -s irc.rizon.net -c '#AnimeNSK' "ANSK|${bot}" send "$pack" 
done
# cp "$tmpfile" .
