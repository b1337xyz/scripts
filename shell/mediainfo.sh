#!/usr/bin/env bash
mj() { mediainfo --Output=JSON "$@"; }
mpj() { mj "$@" | jq . | bat -l json; }
lsd() {
    find "${@:-.}" -maxdepth 1 -iregex '.*\.\(mp3\|opus\|mkv\|mp4\|m4v\|mov\|webm\|avi\|mpg\)' -print0 |
    sort -zV | xargs -r0 mediainfo --Output=JSON | jq -Mcr '
.. | .media? // empty | [
    .["@ref"],
    ( .track[] | select(.["@type"] == "General") | .Duration )
] | "\(.[1]);\(.[0])"'
}
plsd() {
    lsd "${@:-.}" | awk -F';' 'BEGIN { total = 0 }
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
    sub(/\./, "", $1)
    total += $1 + 0
    d = convert_mms($1)
    printf("\033[1;34m%s\033[m - \033[1;35m%s\033[m\n", d, $2)

} END {
    if (NR > 1)
        printf("Total: \033[1;32m%s\033[m\n", convert_mms(total))
}'
}
lsres() {
    find "${@:-.}" -maxdepth 1 -iregex '.*\.\(jpg\|png\|jpeg\|mp4\|avi\|webm\|gif\|m4v\|mkv\)' -print0 |
        xargs -r0 mediainfo --Output=JSON |
        jq -Mcr '.. | .media? // empty |
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
    find . -maxdepth 1 -iregex '.*\.\(jpg\|png\|jpeg\|mp4\|webm\|gif\)' -print0 |
    xargs -r0 mediainfo --Output=JSON |
    jq -Mcr '.. | .media? // empty |
    [
        .["@ref"],
        ((.track[] |
            select(.["@type"] == "Image" or .["@type"] == "Video"
        ) | .Width) | tonumber ),
        ((.track[] |
            select(.["@type"] == "Image" or .["@type"] == "Video"
        ) | .Height) | tonumber )
    ] | select(.[2] > .[1]) | .[0]' #| nsxiv -itq 2>/dev/null
}
all1080p() {
    find . -maxdepth 1 -type f -name '*.jpg' -print0 |
        xargs -P 2 -r0 mediainfo --Output=JSON |
        jq -Mcr '.. | .media? // empty |
        [
            .["@ref"],
            ( (.track | .. | .Width?  // empty) | tonumber ),
            ( (.track | .. | .Height? // empty) | tonumber ) 
        ] |
        select(.[1] > 1920 and .[2] > 1080 and .[1] > .[2]) | .[0]' | while read -r i
    do
        out="1080p_${i##*/}"
        convert -verbose -resize 1920x1080\! "$i" "${i%/*}/$out" && rm -v "$i"
    done
}
mvbyres() {
    find . -maxdepth 1 -iregex '.*\.\(webp\|jpg\|png\|jpeg\|mp4\|avi\|webm\|gif\|m4v\|mkv\)' -print0 |
        xargs -r0 mediainfo --Output=JSON |
        jq -Mcr '.. | .media? // empty |
        [
            .["@ref"],
            ((.track[] |
                select(.["@type"] == "Image" or .["@type"] == "Video"
            ) | .Width) | tonumber ),
            ((.track[] |
                select(.["@type"] == "Image" or .["@type"] == "Video"
            ) | .Height) | tonumber )
        ] | "\(.[1])x\(.[2]) \(.[0])"' | sort -n | while read -r i
        do
            d="${i%% *}" f="${i#* }"
            test -d "$d" || mkdir -v "$d"
            mv -vn "$f" "$d"
        done
}
