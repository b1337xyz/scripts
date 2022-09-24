#!/usr/bin/env python3
import googleapiclient.discovery
import json
import os
import socket
import subprocess as sp
import sys

# https://developers.google.com/youtube/v3/quickstart/python

SOCKET_PATH = '/tmp/mpvradio'
HOME = os.getenv('HOME')
HIST = os.path.join(HOME, '.cache/yt_history')
CONF = os.path.join(HOME, '.config/.ytapi')
API_KEY = open(CONF, 'r').readline().strip()


def fzf(args: list, opts: list):
    proc = sp.Popen(
       ["fzf"] + opts,
       stdin=sp.PIPE, stdout=sp.PIPE,
       universal_newlines=True
    )
    out = proc.communicate('\n'.join(args))
    if proc.returncode not in [0, 1]:
        sys.exit(proc.returncode)
    return [i for i in out[0].split('\n') if i]


def main():
    try:
        with open(HIST, 'r') as fp:
            hist = [i.strip() for i in fp.readlines() if i]
    except FileNotFoundError:
        hist = list()

    if hist:
        hist_len = len(hist)
        lines = hist_len if hist_len <= 20 else 20
        query = fzf(hist, [
            '--height', str(lines), '--prompt', 'search: ',
            '--print-query'
        ])[-1]
    else:
        query = input('search: ').strip()

    if query not in hist:
        with open(HIST, 'a') as fp:
            fp.write(query + '\n')

    youtube = googleapiclient.discovery.build(
        'youtube', 'v3', developerKey=API_KEY)
    request = youtube.search().list(
        q=query.replace(' ', '-'),
        type='video,playlist',
        part="id,snippet",
        safeSearch='none',
        maxResults=25
    )
    response = request.execute()

    videos = {
        i['snippet']['title']: i['id']['videoId']
        for i in response['items']
    }
    output = fzf(videos.keys(), ['-m', '--height', '25'])
    playlist = "/tmp/mpv.m3u"
    with open(playlist, "w") as fp:
        fp.write("#EXTM3U\n")
        for k in output:
            url = f'https://www.youtube.com/watch?v={videos[k]}'
            fp.write(f"#EXTINF:0, {k}\n{url}\n")

    mpv = socket.socket(socket.AF_UNIX)
    mpv.connect(SOCKET_PATH)
    cmd = {"command": ["loadlist", playlist]}
    mpv.send(json.dumps(cmd).encode('utf-8') + b'\n')


if __name__ == '__main__':
    main()
