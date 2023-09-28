#!/bin/sh
set -e

DIR=~/Pictures/wallpapers

cd "$DIR"

is_green() {
    convert "$1" -scale 50x50\! -depth 8 +dither -colors 8 -format "%c" histogram:info: |
    sort -rn | awk '{
        match($2, /\(([0-9\.]+),([0-9\.]+),([0-9\.]+)/, rgb)
        r = rgb[1] + 2
        g = rgb[2] + 0
        b = rgb[3] + 1
        exit !(g > r && g > b)
    }'  
}

is_dark() {
    convert "$1" -format "%[fx:int(mean * 100)]" info: | awk '{exit !( ($1 + 0) < 25)}'
}

resize() {
    mediainfo --Output=JSON "$1" | jq -Mcr '.media? |
        [
            .["@ref"],
            ( (.track | .. | .Width?  // empty) | tonumber ),
            ( (.track | .. | .Height? // empty) | tonumber ) 
        ] |
        if .[1] >= 3840 and .[2] >= 2160 then
            "50% \(.[0])"
        elif .[1] >= 2400 and .[2] >= 1350 then
            "80% \(.[0])"
        else
            empty
        end' | while read -r p f; do mogrify -verbose -resize "$p" "$f"; done

    return 0
}

convert_and_remove() {  # convert and remove the original image
    convert -verbose "$1" "$2" && rm -v "$1"
}

lock=/tmp/.walld
[ -f "$lock" ] && { printf 'lock file %s exists, already running?' "$lock"; exit 1; }
:>"$lock"
trap 'rm $lock' EXIT INT

cache=.skip
[ -f "$cache" ] || :>"$cache"
mkdir -vp green dark

inotifywait -r -m -e create,close_write,moved_to --format '%w%f%0' "$DIR" | while IFS= read -r file
do
    [ -f "$file" ] || continue
    grep -qxF "$file" "$cache" && { printf 'skipping "%s"\n' "$file"; continue; }
    sleep 1

    new=${file}.jpg
    mime=$(file -bi "$file")
    case "${mime%%;*}" in
        image/jpeg) true ;;
        image/gif)
            convert_and_remove "${file}[0]" "$new" || continue
            file=$new ;;
        image/*)
            convert_and_remove "$file" "$new" || continue
            file=$new ;;
        *) continue ;;
    esac

    resize "$file"

    md5=$(md5sum "$file" | awk '{print $1}')
    new=${file%/*}/${md5}.jpg
    mv -vf "$file" "$new"
    file=$new

    is_green "$file" && ln -frs "$file" green
    is_dark "$file"  && ln -frs "$file" dark

    chmod -v 600 "$file"

    echo "$file" >> "$cache"
done
