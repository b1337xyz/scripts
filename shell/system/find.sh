#!/bin/sh
e='.*\.(bdic|tdb|lpl|spl|state[0-9]?|srm|png|jpg|auto|crt|rev|pem|lock|key|[0-9][0-9][0-9]+|log|idx|cache|bin|fur)$'

find "$1" -maxdepth 8 -regextype posix-extended -type f \( -size +30c -and -size -100k \) \
    \! \( -path '*/node_modules*' -o \
          -path '*/nvm*' -o \
          -path '*/retroarch*' -o \
          -path '*/libresprite*' -o \
          -path '*__*__*' -o \
          -path '*/venv/*' -o \
          -path '*/.git/*' -o \
          -path '*/go/*' -o \
          -path '*/discord/*' -o \
          -path '*/blender/*' -o \
          -path '*/plugged/*' -o \
          -path '*/gnupg/*' -o \
          -path '*/GIMP/*' -o \
          -path '*/chromium/*' -o \
          -path '*/YouTube*' -o \
          -path '*/playlists/*' -o \
          -iregex "$e" \)
