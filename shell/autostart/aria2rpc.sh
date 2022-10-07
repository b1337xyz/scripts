#!/bin/sh
session=~/.cache/aria2/session

pkill -f 'aria2c -D -V --enable-rpc'
aria2c -D -V --enable-rpc --input-file "$session"
