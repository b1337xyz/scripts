#!/usr/bin/env python3
from optparse import OptionParser
import googleapiclient.discovery
import json
import os
import socket
import subprocess as sp
import sys

# HOW TO GET THE API_KEY -> https://developers.google.com/youtube/v3/quickstart/python
# before running this start mpv with:
# mpv --keep-open=yes --idle=yes --ytdl-format="ba" \
#     --cache=yes --no-video --input-ipc-server=<SOCKET_PATH>

SOCKET_PATH = '/tmp/mpvradio'
HOME = os.getenv('HOME')
HIST = os.path.join(HOME, '.cache/yt_history')
CONF = os.path.join(HOME, '.config/.ytapi')
API_KEY = open(CONF, 'r').readline().strip()


def run(prog: str, args: list, opts: list):
    proc = sp.Popen(
       [prog] + opts,
       stdin=sp.PIPE, stdout=sp.PIPE,
       universal_newlines=True
    )
    out = proc.communicate('\n'.join(args))
    if proc.returncode not in [0, 1]:
        sys.exit(proc.returncode)
    return [i for i in out[0].split('\n') if i]


def parse_arguments():
    parser = OptionParser()
    parser.add_option('--dmenu', action='store_true')
    parser.add_option('--fzf', action='store_true', default=True)
    return parser.parse_args()


def main():
    opts, args = parse_arguments()

    try:
        with open(HIST, 'r') as fp:
            hist = [i.strip() for i in fp.readlines() if i]
    except FileNotFoundError:
        hist = list()

    if opts.dmenu:
        query = run('dmenu', [], ['-c', '-p', 'search:'])[-1]
    else:
        if hist:
            hist_len = len(hist)
            h = hist_len if hist_len <= 20 else 20
            query = run('fzf', hist, [
                '--height', str(h), '--prompt', 'search: ',
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
    if opts.dmenu:
        output = run('dmenu', videos.keys(), ['-c', '-l', '25'])
    else:
        output = run('fzf', videos.keys(), ['-m', '--height', '25'])

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
