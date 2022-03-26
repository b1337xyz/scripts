#!/usr/bin/env bash
# shellcheck disable=SC2030

parse_query() {
    printf '%s' "$1" | tr -cd '[:print:]' |
        tr '[:upper:]' '[:lower:]' | sed "s/'//g; s/\"//g" | sed -e '
        s/\!/ /g;
        s/\(_\|\s\)[0-9]*-[0-9]*\(\s\|_\|$\)/ /g;
        s/\(-\|_\|~\)/ /g;
        s/\///g;
        s/\[[^][]*\]//g;
        s/([^()]*)//g;
        s/\(dvd\|blu.\?ray\)//g;
        s/\(especial\|special\)$//g;
        s/\(hdtv\|[0-9]\{3,4\}x[0-9]\{3,4\}\|[0-9]\{4\}p\)//g;
        s/\sbd$//g;
        s/\s+\s/ /g;
        s/\s\{2,\}/ /g;
        s/^\s*//g;
        s/\s*$//g;'
}

mal_t=~/.scripts/shell/fzf_scripts/mal_titles.csv

pv() {
    ls -1 "./${1}"
    mal_f=~/.scripts/shell/fzf_scripts/mal.csv
    grep -iF "${2}|" "$mal_f" | while IFS='|' read -r title type episodes rated;do
        printf '\n%s\nType: %s\nEpisodes: %s\nRated: %s\n' "$title" "$type" "$episodes" "$rated" 
    done
}
export -f pv

if [ -z "$1" ];then
    find . -mindepth 1 -maxdepth 1 | while read -r i;do
        query="${i##*/}"
        # shellcheck disable=SC2030
        [ -f "$i" ] && query="${query%.*}"
        query=$(parse_query "$query")

        title=$(fzf -q "$query" --header="$i" --preview "pv \"${i}\" {}" < "$mal_t")
        [ -z "$title" ] && continue
        mv -nv "$i" "./${title}"
    done
else
    query="$1"
    [ -f "$i" ] && query="${query%.*}"
    query=$(parse_query "$query")

    title=$(fzf -q "$query" --header=">>> $1" --preview "pv \"${1}\" {}" < "$mal_t")
    mv -nv "$1" "./${title}"
fi
