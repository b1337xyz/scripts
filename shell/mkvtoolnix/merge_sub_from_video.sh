#!/bin/sh

# -A, --no-audio
# -D, --no-video
# -S, --no-subtitles
# -M, --no-attachments

# mkvmerge -J "$2" | jq -r '.tracks[] |
# "\(.type): \(.id) - \(.properties.language) - \(.properties.track_name) \(
# if .properties.default_track then "(default)" else "" end)"'

mkvmerge -o new_"${1##*/}" -S -M -a jpn "$1" -D -A -s por "$2"
# mkvmerge -o new_"${1##*/}" "$1" -D -A "$2"
# mkvmerge -o new_"${1##*/}" -S -M "$1" -A -D --no-chapters --language 2:por --track-name 2:"Portuguese" "$2"
# mkvmerge -o new_"${1##*/}" --default-track 2:0 --forced-track 2:0 "$1" -A -D --no-chapters --language 2:por --track-name 2:"Portuguese" "$2"
