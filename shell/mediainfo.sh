#!/usr/bin/env bash
lsd() {
    find "${@:-.}" -maxdepth 1 -iregex '.*\.\(mp3\|opus\|mkv\|mp4\|m4v\|mov\|webm\|avi\)' -print0 |
    sort -zV | xargs -r0 mediainfo --Output=JSON | jq -Mcr '
.[].media | select(.track[]["@type"] == "Video") | 
[
    .["@ref"],
    ( .track[] | select(.["@type"] == "General") | .Duration )
] | "\(.[0]);\(.[1])"' | awk -F';' 'BEGIN { total = 0 }

function convert_mms(n) {
    ss = int( (n + 0) / 1000)
    hh = int(ss / 3600)
    mm = int(ss / 60) % 60
    if (ss >= 60) ss %= 60
    if ( mm >= 60 ) mm %= 60
    if ( hh < 10 ) hh = "0"hh
    if ( mm < 10 ) mm = "0"mm
    if ( ss < 10 ) ss = "0"ss

    return hh":"mm":"ss
}

{
    sub(/\./, "", $2)
    total += $2 + 0
    d = convert_mms($2)
    printf("\033[1;34m%s:\033[m - \033[1;35m%s\033[m\n", d, $1)

} END { printf("Total: \033[1;32m%s\033[m\n", convert_mms(total)) }'
}
lsres() {
    find "${@:-.}" -maxdepth 1 -iregex '.*\.\(webp\|jpg\|png\|jpeg\|mp4\|avi\|webm\|gif\|m4v\|mkv\)' -print0 |
        xargs -r0 mediainfo --Output=JSON |
        jq -Mcr '.[].media? // empty |
        [
            .["@ref"],
            ((.track[] |
                select(.["@type"] == "Image" or .["@type"] == "Video"
            ) | .Width) | tonumber ),
            ((.track[] |
                select(.["@type"] == "Image" or .["@type"] == "Video"
            ) | .Height) | tonumber )
        ] | "\(.[1])x\(.[2]) \(.[0])"'
    # printf '%sx%-4s %s\n' "$width" "$height" "$i"
}
killflac() {
    find "${@:-.}" -iregex '.*\.\(mkv\|mp4\)' -print0 |
    xargs -r0  mediainfo --Output=JSON |
    jq -Mrc '
    [
        .media["@ref"],
        (.media.track[] | select(.["@type"] == "Audio") | .Format)
    ] | select(.[1] == "FLAC") | .[0]' 2>/dev/null
}
tall() {
    out=tall
    [ -d "$out" ] || { mkdir -v "$out" || return 1; }
    find . -maxdepth 1 -iregex '.*\.\(jpg\|png\|jpeg\|mp4\|webm\|gif\)' -print0 |
    xargs -P 2 -r0 mediainfo --Output=JSON |
    jq -Mcr '.[].media? |
    [
        .["@ref"],
        ((.track[] |
            select(.["@type"] == "Image" or .["@type"] == "Video"
        ) | .Width) | tonumber ),
        ((.track[] |
            select(.["@type"] == "Image" or .["@type"] == "Video"
        ) | .Height) | tonumber )
    ] |
    select(.[2] > .[1]) | .[0]' | while read -r i;
    do
        mv -vn -- "$i" "$out"
    done
}
