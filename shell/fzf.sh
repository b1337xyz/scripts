fonts() {
    fc-list | cut -d':' -f2- | sort -u | fzf |
        tr -d \\n | sed 's/^\s*//' | xclip -sel c
}
fzbtm() {
    find ~/.config/bottom/*.toml | fzf --layout=reverse \
        --height 10 --print0 | xargs -0or btm -C
}
show() {
    file -Li ~/.local/bin/* | grep --color=never -oP '.*(?=:[\t ]*text/)' |
        fzf --layout=reverse --height 10 --print0 | xargs -0r bat
    echo
}
ffp() {
    find . -maxdepth 1 -type f | fzf --preview-window "right:60%" \
        --preview 'bat --style=numbers --color=always --line-range :100 {}'
}
_fzfile() {
    fzf -e --scheme=path --tiebreak=end --layout=reverse --no-border --no-scrollbar "$@" \
        --bind 'ctrl-t:toggle-preview' \
        --preview 'file -Lbi {} | grep -q ^text && bat --color=always {}' \
        --preview-window 'hidden,border-none'
}
e() { 
    local file
    file=$(find "${1:-.}" -maxdepth 6 -xdev -type f -size -100k -regextype posix-extended \
        \! \( -path '*/node_modules*' -o -path '*cache/*' -o -path '*__*__*' -o -path '*/venv/*' \) \
        2>/dev/null | _fzfile)
    [ -f "$file" ] && $EDITOR "$file"
}
s() {
    local file
    file=$(~/.scripts/shell/system/find.sh ~/.scripts |
        _fzfile -d "${HOME}/" --with-nth 2..)
    [ -f "$file" ] && $EDITOR "$file"
}
c() { 
    local file
    file=$(~/.scripts/shell/system/find.sh ~/.config |
        _fzfile -d "${HOME}/" --with-nth 2..)
    [ -f "$file" ] && $EDITOR "$file"
}
fzumount() {
    command df -x efivarfs -x tmpfs -x devtmpfs | tail -n +2 | sort -Vr |
        awk '!/sda|nvme/{printf("%-20s %s\n", $1, $6)}' |
        fzf -m --layout=reverse --height 10 | awk '{print $1}' |
        xargs -roI{} sudo umount '{}' && sleep 1 &&
        command df -h -x tmpfs -x devtmpfs | grep -vP '/dev/sda|nvme'
}
fztorrent() {
    find ~/.cache/torrents -iname '*.torrent' -printf '%f\n' | sort -V |
    fzf --layout=reverse --height 20 -m | sed -e 's/[]\[?\*\$]/\\&/g' | tr \\n \\0 |
        xargs -0rI{} find ~/.cache/torrents -type f -name '{}'
}
cptorrent() { fztorrent | tr \\n \\0 | xargs -0rI{} cp -v '{}' . ;}
fzcbt() {
    local cache
    cache=~/.cache/torrents/torrents.txt
    if [ -f "$cache" ];then
        cat "$cache"
    else
        aria2c -S ~/.cache/torrents/*/*.torrent |
            awk -F'\\|\\./' '/[0-9]\|\.\//{print $2}' | tee "$cache"
    fi | fzf "$@" | awk -F'/' '{print $2}' |
         sed -e 's/[]\[?\*\$]/\\&/g' | tr \\n \\0 |
         xargs -0rI{} find ~/.cache/torrents -type f -name '{}.torrent'
}
fzbt() {
    find . -maxdepth 3 -iname '*.torrent' | fzf \
        --preview 'aria2c -S {}' --preview-window 'border-sharp'
}
alacritty_theme_switcher() {
    local config themes
    config=~/.config/alacritty/alacritty.toml
    themes=~/.config/alacritty/themes
    cp -v "$config" "${config}.bkp"
    # shellcheck disable=SC2317
    pv() {
        sed -i "s/\/themes\/.*\.toml/\/themes\/${1}/" ~/.config/alacritty/alacritty.toml
        bat --style=numbers --color=always --line-range :15 ~/.bashrc
        ls -x --color=always ~/
        bash ~/.scripts/playground/shell/Colors/panes
        bash ~/.scripts/playground/shell/Colors/spectrum
        bash ~/.scripts/playground/shell/Colors/bars
    }
    export -f pv
    find "$themes" -type f -printf '%f\n' | sort |
        fzf -e --preview-window "border-none:right:60%" --preview 'pv {}'
    unset pv

    read -r -p 'Undo? (y/n) ' ask
    [ "${ask,,}" = "y" ] && cp -v "${config}.bkp" "$config"

    return 0
}
dlbkp() {
    local target
    local cache=/tmp/.dlbkp
    target=${1:-.}
    if ! [ -e "$cache" ];then
        rclone lsf gdrive:backups | sort -V > "$cache"
    fi

    dl() {
        for i in "$@";do
            rclone copy -P gdrive:backups/"$i" "$target"
        done
    }
    export -f dl
    while read -r i;do
        [ -n "$i" ] && dl "$i" 
    done < <(fzf --tac --height 20 -e -m --bind 'ctrl-d:execute(dl {+})' < "$cache")
    unset dl
}
fzopen() {
    find "${1:-.}" -maxdepth 6 -xdev -type f -regextype posix-extended \
        -iregex '.*\.(mkv|mp4|webm|avi|m4v|epub|pdf|jpe?g|png)' |
        fzf --bind 'enter:execute-silent(xdg-open {} & disown)+accept'
}
fzpac() { 
    pacman "${@:--Qqe}" | fzf -m --header '^r ^s ^d' \
        --preview='pacman -Qi {}' --preview-window '70%' \
        --bind 'enter:reload(yay -Ssq {q})' \
        --bind 'ctrl-r:execute(sudo pacman -Rs {+})+reload(pacman -Qqe)' \
        --bind 'ctrl-s:execute(yay -Syu {+})' \
        --bind 'ctrl-d:execute(sudo downgrade {+})'
}
fzman() {
    [ -z "$1" ] && { printf 'Usage: fzman term\n'; return 1; }

    # shellcheck disable=SC2016
    man -P cat "$1" 2>/dev/null | grep '^[A-Z]' |
        sed -e '1d' -e '$ d' | fzf |
        sed -e 's/[]\[?\*\$()]/\\\\&/g' |
        xargs -rI{} man -P 'less -p"^{}"' "$1"
}
gitlog() {
    git log "${1:-.}" | grep -oP '(?<=^commit ).*' | fzf --cycle --preview-window '80%' --preview 'git show --color=always {}' | xargs -r git show
}
fzkill() {
    ps -u "$USER" h -o 'pid:1' -o cmd | fzf -m --tac --prompt 'kill> ' --height 25 | cut -d' ' -f1 | xargs -r kill
}
fdel() {
    find "${1:-.}" -maxdepth 2 -xdev -type f | fzf --print0 | xargs -r0 rm -vI
}
menu() { 
    fzf -m -0 --no-separator --no-scrollbar --disabled \
        --prompt='' --height=~20 --layout=reverse-list \
        --cycle --border=none --no-info --no-sort \
        --color gutter:-1,query:black \
        --bind 'j:down' --bind 'k:up'
}
psndl() {
    local db cat
    db=~/.cache/psndl.csv
    cat=$(grep -oP '(?<=;)[^;]*(?=;[^;]*;https?:)' "$db" | sort -u | fzf -m --algo v1)
    grep -F ";${cat};" "$db" | grep -oP '.*(?=;https?:)' |
        fzf -m | xargs -rIV grep -F 'V' "$db" | grep -oP '(?<=;)http[^;]*' |
        aria2c -j 1 --dir ~/Downloads --input-file=-
}
