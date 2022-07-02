#!/usr/bin/env bash
convert_mms() {
    local hh ss mm
    hh=0
    ss=$(( $1 / 1000 ))
    mm=$(( ss / 60 ))
    ss=$(( ss - ( mm * 60 ) ))
    if [ "$mm" -ge 60 ];then
        hh=$(( mm / 60 ))
        mm=$(( mm % 60 ))
    fi
    [ "$hh" -lt 10 ] && hh="0$hh"
    [ "$mm" -lt 10 ] && mm="0$mm"
    [ "$ss" -lt 10 ] && ss="0$ss"
    printf '%s:%s:%s' "$hh" "$mm" "$ss"
}
lsd() {
    local total=0
    if [ -f "$1" ];then
        for i in "$@";do
            mms=$(mediainfo --Output='General;%Duration%' "$i" | cut -d'.' -f1)
            [ -z "$mms" ] && return 1
            (( total += mms ))
            duration=$(convert_mms "$mms") 
            printf '\e[1;34m%s\e[m - \e[1;35m%s\e[m\n' "$duration" "$i"
        done
    else
        while read -r i;do
            # mediainfo --Output='General;%CompleteName%: %Duration/String%' "$i";
            mms=$(mediainfo --Output='General;%Duration%' "$i")
            [ -z "$mms" ] && continue
            (( total += mms ))
            duration=$(convert_mms "$mms") 
            printf '\e[1;34m%s\e[m - \e[1;35m%s\e[m\n' "$duration" "$i"
        done < <(find "${1:-.}" -mindepth 1 -maxdepth 1 \
            -iregex '.*\.\(mp[3-4]\|wav\|opus\|mkv\|avi\|webm\)' | sort)
    fi

    [ "$total" -eq 0 ] && return 1
    if [ "$total" -ne "$mms" ];then
        duration=$(convert_mms "$total")
        printf 'Total: \e[1;32m%s\e[m\n' "$duration"
    fi
}
lsres() {
    find "${@:-.}" -iregex '.*\.\(webp\|jpg\|png\|jpeg\|mp4\|avi\|webm\|gif\|m4v\|mkv\)' -print0 |
        xargs -r0 mediainfo --Output=JSON |
        jq -Mcr '.[].media? // empty |
        [
            .["@ref"],
            ( (.track | .. | .Width?  // empty) | tonumber ),
            ( (.track | .. | .Height? // empty) | tonumber ) 
        ] | "\(.[1])x\(.[2]) \(.[0])"'
    # printf '%sx%-4s %s\n' "$width" "$height" "$i"
}
all1080p() {
    find . -maxdepth 1 -type f -iname '*.jpg' | while read -r i;do
        out="1080p_${i##*/}"
        IFS='x' read -r width height < <(mediainfo --Output='Image;%Width%x%Height%' "$i")
        [ -z "$width" ] && continue
        [ -z "$height" ] && continue
        [ "$width" -le 1920 ] && continue
        [ "$height" -le 1080 ] && continue
        [ "$width" -lt "$height" ] && continue
        convert -verbose -resize 1920x1080\! "$i" "$out" && rm -vf "$i"
    done
}
killflac() {
    find "${1:-.}" -type f -iregex '.*\.\(mkv\|mp4\)' | sort | while read -r i;do
        mediainfo --Output='Audio;%Format%' "$i" |
            grep -qi flac && printf '%s\n' "$i"
    done

    return 0
}
killflac2() {
    find "${1:-.}" -iregex '.*\.\(mkv\|mp4\)' -print0 |
    xargs -r0  mediainfo --Output=JSON |
    jq -Mrc '
    [
        .media["@ref"]
    ] + [
        .media.track[] | select(.["@type"] == "Audio") | .Format
    ] | select(.[1] == "FLAC") | .[0]' 2>/dev/null
}
