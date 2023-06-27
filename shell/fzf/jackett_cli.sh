#!/usr/bin/env bash

set -eo pipefail

#  /api/v2.0/indexers/<Filter>/results
#  /api/v2.0/indexers/tag:group1,!type:private+lang:en/results
#
# Filter 	                          Condition
# type:<type> 	                    where the indexer type is equal to <type>
# tag:<tag> 	                      where the indexer tags contains <tag>
# lang:<tag> 	                      where the indexer language start with <lang>
# test:{passed|failed}              where the last indexer test performed passed or failed
# status:{healthy|failing|unknown} 	where the indexer state is healthy (successfully operates in the last minutes),
#                                   failing (generates errors in the recent call) or unknown (unused for a while)
# A list of supported API search modes and parameters:
# t=search:
#    params  : q
# t=tvsearch:
#    params  : q, season, ep, imdbid, tvdbid, rid, tmdbid, tvmazeid, traktid, doubanid, year, genre
# t=movie:
#    params  : q, imdbid, tmdbid, traktid, doubanid, year, genre
# t=music:
#    params  : q, album, artist, label, track, year, genre
# t=book:
#    params  : q, title, author, publisher, year, genre

# Examples:
# .../api?apikey=APIKEY&t=search&cat=1,3&q=Show+Title+S01E02
# .../api?apikey=APIKEY&t=tvsearch&cat=1,3&q=Show+Title&season=1&ep=2
# .../api?apikey=APIKEY&t=tvsearch&cat=1,3&genre=comedy&season=2023&ep=02/13
# .../api?apikey=APIKEY&t=movie&cat=2&q=Movie+Title&year=2023
# .../api?apikey=APIKEY&t=movie&cat=2&imdbid=tt1234567
# .../api?apikey=APIKEY&t=music&cat=4&album=Title&artist=Name
# .../api?apikey=APIKEY&t=book&cat=5,6&genre=horror&publisher=Stuff


declare -r -x API_KEY=API_KEY_HERE
declare -r -x API_URL=http://localhost:9117/api/v2.0/indexers
declare -r -x CACHE_DIR=~/.cache/jackett_cli
declare -r -x FILE=/tmp/jackett_cli.$$.json

trap 'rm $FILE 2>/dev/null' EXIT

main() {
    [ -z "$1" ] && return
    case "$1" in
        sort_by) 
            curl -s -XPOST localhost:1337 -d "change-prompt((Sorted by ${2}) Search: )" || true
            jq -Mcr --arg k "$2" '.Results as $r | $r | [to_entries[] | {k: .key, v: .value[$k]}] | sort_by(.v)[] | "\(.k):\($r[.k].Title)"' "$FILE"
        ;;
        *)
            curl -s -XPOST localhost:1337 -d "change-prompt(Searching... )" || true
            curl -s "${API_URL}/1337x/results?apikey=${API_KEY}&Query=${1// /+}" -o "$FILE"
            jq -Mcr '.Results | to_entries[] | "\(.key):\(.value.Title)"' "$FILE"
            curl -s -XPOST localhost:1337 -d "change-prompt(Search: )" || true
        ;;
    esac
}

preview() {
    # jq -C --argjson i "$1" '.Results[$i] | keys[]' "$FILE" | bat
    jq -Mcr --argjson i "$1" --argjson units '["B", "K", "M", "G", "T", "P"]' '
    def psize(size;i):
        if (size < 1000) then
            "\(size * 100 | floor | ./100) \($units[i])"
        else
            psize(size / 1000;i+1)
        end;

    .Results[$i] | "Tracker: \(.Tracker)
Type: \(.TrackerType)
Title: \(.Title)
Category: \(.CategoryDesc)
Date: \(.PublishDate)
Size: \(psize(.Size;0))
Grabs: \(.Grabs)
Seeders: \(.Seeders)
Peers: \(.Peers)
"' "$FILE"

}

init() {
    if ! [ -d "$CACHE_DIR" ];then
        printf 'Downloading Definitions...\n'
        curl -s 'https://github.com/Jackett/Jackett/tree/487cacf96716317299fdf4b11287a96fa4918552/src/Jackett.Common/Definitions' |
            grep -oP '(?<=href=")[^"]+\.yml' | sed 's/\/blob//; s/^/https:\/\/raw.githubusercontent.com/' |
            aria2c -q -j 2 --allow-overwrite=false --auto-file-renaming=false --dir="$CACHE_DIR" --input-file=- 
    fi
} && init

export -f preview main
main "$*" | fzf --tac --listen 1337 \
    --header "Sort: C-s Seeders C-g Grabs C-p Peers A-s Size" \
    --prompt 'Search: ' \
    --no-border --no-sort \
    --preview 'preview {1}' \
    --delimiter ':' --nth 2.. --with-nth 2.. \
    --bind 'enter:reload(main {q})+clear-query' \
    --bind 'ctrl-l:last' --bind 'ctrl-f:first' \
    --bind 'ctrl-s:reload(main sort_by Seeders)' \
    --bind 'ctrl-g:reload(main sort_by Grabs)' \
    --bind 'ctrl-p:reload(main sort_by Peers)' \
    --bind 'alt-s:reload(main sort_by Size)'
