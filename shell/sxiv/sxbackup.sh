#!/bin/sh

sxiv -qato | tr '\n' '\0' | tar czvf "backup_$(date +%Y%m%d%H).tar.gz" --null -T -
