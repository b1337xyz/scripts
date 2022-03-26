#!/bin/sh

# -A, --no-audio
# -D, --no-video
# -S, --no-subtitles
# -M, --no-attachments
mkvmerge -o new_"${1##*/}" -S -M "$1" -A -D --no-chapters "$2"
# mkvmerge -o new_"${1##*/}" -S -M "$1" -A -D --no-chapters --language 2:por --track-name 2:"Portuguese" "$2"
#mkvmerge -o new_"${1##*/}" --default-track 2:0 --forced-track 2:0 "$1" -A -D --no-chapters --language 2:por --track-name 2:"Portuguese" "$2"
