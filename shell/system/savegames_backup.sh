#!/bin/sh
export ZSTD_CLEVEL=19
find ~/Games \( -name AppData -o -name 'Saved Games' \) -print0 | tar --zstd -cf saves_$(date +%Y.%m.%d).tar.zst --null --files-from=-
