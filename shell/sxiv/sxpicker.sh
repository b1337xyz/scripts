#!/usr/bin/env bash
set -eo pipefail
find ~/Pictures -iregex '.*\.\(jpg\|png\|gif\|jpeg\)' -printf '%h\n' |
    sort -u | dmenu -l 20 -c -i | tr \\n \\0 | xargs -r0I{} sxiv -qotr '{}' 2>/dev/null
