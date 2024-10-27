#!/bin/sh
export ZSTD_CLEVEL=19
find ~/Games/Lutris \( -name AppData -o -name 'Saved Games' \) -print0 | tar --zstd -cf saves.tar.zst --null --files-from=-
